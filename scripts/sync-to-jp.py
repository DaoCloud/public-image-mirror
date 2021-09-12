import os
import json
import random
import subprocess

REPO_REPLACE_RULE1 = {
    "k8s.gcr.io":"k8s-gcr-jp.m.daocloud.io"
}

REPO_REPLACE_RULE2 = {
    "gcr.io":"gcr-jp.m.daocloud.io",
    "docker.io":"docker-jp.m.daocloud.io",
    "quay.io":"quay-jp.m.daocloud.io",
    "ghcr.io":"ghcr-jp.m.daocloud.io"
}
#    "":"",

INTERNAL_NETWORK = {
    "k8s-gcr-jp.m.daocloud.io":"10.40.134.38:6001",
    "gcr-jp.m.daocloud.io":"10.40.134.38:5001",
    "docker-jp.m.daocloud.io":"10.40.134.38:7001",
    "quay-jp.m.daocloud.io":"10.40.134.38:8001",
    "ghcr-jp.m.daocloud.io":"10.40.134.38:9001"
}


REGISTRY_PASSWORD = os.environ["REGISTRY_PASSWORD"]
DELTA_MODE = os.environ.get("DELTA_MODE") 
DRY_RUN = os.environ.get("DRY_RUN")

# SKEPO_CMD = "docker run --rm quay.io/containers/skopeo:latest"
SKEPO_CMD = "skopeo" # RUN without docker

def __run_cmd(cmd):
    print(cmd)
    if not DRY_RUN:
        os.system(cmd)

def __dest_img(src_img):
    dest_img = src_img
    for k,v in REPO_REPLACE_RULE1.items():
        dest_img = dest_img.replace(k,v)
    for k,v in REPO_REPLACE_RULE2.items():
        dest_img = dest_img.replace(k,v)
    for k,v in INTERNAL_NETWORK.items():
        dest_img = dest_img.replace(k,v)
    return dest_img


def skepo_full_sync(src_img):
    dest_img = __dest_img(src_img)
    dest_img = "/".join(dest_img.split("/")[:-1])
    cmd = SKEPO_CMD + " sync --src docker --dest docker --dest-tls-verify=false --dest-creds root:%s -f oci %s %s" %(REGISTRY_PASSWORD,src_img,dest_img)
    __run_cmd(cmd)

def __parse_tag(output):
    # print(output)
    try:
        return json.loads(output).get('Tags',[])
    except:
        return []

def skepo_delta_sync(src_img):
    dest_img = __dest_img(src_img)
    cmd = "skopeo list-tags docker://" + src_img
    result = subprocess.run(cmd, shell=True,stdout=subprocess.PIPE)
    src_tags = __parse_tag(result.stdout)
    cmd = "skopeo list-tags  --creds root:%s  --tls-verify=false docker://%s" %(REGISTRY_PASSWORD,dest_img)
    print(cmd)
    result = subprocess.run(cmd, shell=True,stdout=subprocess.PIPE)
    dest_tags = __parse_tag(result.stdout)
    need_to_sync = set(src_tags) - set(dest_tags)

    print(src_img)
    print("src %s, dest %s " % (len(src_tags),len(dest_tags)))
    print(need_to_sync)
    if len(need_to_sync) == 0:
        if 'latest' in src_tags:
            cmd = "skopeo copy --dest-creds root:%s  --dest-tls-verify=false -f oci docker://%s:latest docker://%s:latest" %(REGISTRY_PASSWORD,src_img,dest_img)
            __run_cmd(cmd)
    else:
        skepo_full_sync(src_img)

    # print(src_tags)

def main():
    lines = []
    with open("mirror.txt") as f:
        lines = f.readlines()
    random.shuffle(lines)
    sync_cmds = []
    for l in lines:
        src_img = l.strip()
        if DELTA_MODE:
            skepo_delta_sync(src_img)
        else:
            skepo_full_sync(src_img)
        

if __name__ == "__main__":
    # execute only if run as a script
    main()