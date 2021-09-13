import os
import re
import json
import yaml
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
DOCKER_IO_USER = os.environ.get("DOCKER_IO_USER")
DOCKER_IO_PASS = os.environ.get("DOCKER_IO_PASS")

SKOPEO_CMD = "docker run --rm quay.io/containers/skopeo:latest"
# SKOPEO_CMD = "skopeo" # RUN without docker

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
    src_auth = ""
    if 'docker.io' in src_img and DOCKER_IO_USER:
        src_auth = " --src-creds %s:%s " % (DOCKER_IO_USER,DOCKER_IO_PASS)
    cmd = SKOPEO_CMD + " sync --all --src docker --dest docker %s --dest-tls-verify=false --dest-creds root:%s -f oci %s %s" %(src_auth,REGISTRY_PASSWORD,src_img,dest_img)
    __run_cmd(cmd)

def __parse_tag(output):
    # print(output)
    try:
        return json.loads(output).get('Tags',[])
    except:
        return []

def skepo_sync_one_tag(src_img,tag):
    dest_img = __dest_img(src_img)
    src_auth =''
    if 'docker.io' in src_img and DOCKER_IO_USER:
        src_auth = " --src-creds %s:%s " % (DOCKER_IO_USER,DOCKER_IO_PASS)
    cmd = SKOPEO_CMD + " copy --all %s --dest-creds root:%s  --dest-tls-verify=false -f oci docker://%s:%s docker://%s:%s" %(src_auth,REGISTRY_PASSWORD,src_img,tag,dest_img,tag)
    __run_cmd(cmd)

def filter_tag(src_img,delta_tags):
    y = []
    need_to_sync = list(delta_tags)
    with open("not_sync.yaml") as f:
        y = yaml.safe_load(f)
    for n in y.get('not_sync'):
        if bool(re.match(n.get("image_pattern"), src_img)):
            for t in delta_tags:
                for tp in n.get("tag_patterns",[]):
                    if bool(re.match(tp, t)):
                        need_to_sync.remove(t)
    return need_to_sync

def skepo_delta_sync(src_img):
    dest_img = __dest_img(src_img)
    src_auth =''
    if 'docker.io' in src_img and DOCKER_IO_USER:
        src_auth = " --creds %s:%s " % (DOCKER_IO_USER,DOCKER_IO_PASS)
    cmd = "skopeo list-tags %s docker://%s" % (src_auth,src_img)
    print(cmd)
    result = subprocess.run(cmd, shell=True,stdout=subprocess.PIPE)
    src_tags = __parse_tag(result.stdout)
    cmd = "skopeo list-tags  --creds root:%s  --tls-verify=false docker://%s" %(REGISTRY_PASSWORD,dest_img)
    print(cmd)
    result = subprocess.run(cmd, shell=True,stdout=subprocess.PIPE)
    dest_tags = __parse_tag(result.stdout)
    delta_tags = set(src_tags) - set(dest_tags)
    need_to_sync = filter_tag(src_img,delta_tags)
    

    filtered_num = len(delta_tags) - len(need_to_sync)
    if 'latest' in src_tags:
        need_to_sync.append('latest')

    # print(src_img)
    print("sync %s, src tag %s, dest tag %s, sync tag %s, filtered tag %s " % (src_img,len(src_tags),len(dest_tags),len(need_to_sync),filtered_num))
    
    for tag in need_to_sync:
        skepo_sync_one_tag(src_img,tag)

def main():
    lines = []
    with open("mirror.txt") as f:
        lines = f.readlines()
    random.shuffle(lines)
    sync_cmds = []
    for l in lines:
        src_img = l.strip()
        if DELTA_MODE:
            print('use DELTA_MODE')
            skepo_delta_sync(src_img)
        else:
            print('use FULL_SYNC_MODE')
            skepo_full_sync(src_img)
        

if __name__ == "__main__":
    # execute only if run as a script
    main()