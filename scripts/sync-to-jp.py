import os
import random

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


SKEPO_CMD = "docker run --rm quay.io/containers/skopeo:latest"
# SKEPO_CMD = "skepo" # RUN without docker

def skepo_sync_cmd(src_img):
    src_img = src_img.strip()

    dest_img = "/".join(src_img.split("/")[:-1])
    for k,v in REPO_REPLACE_RULE1.items():
        dest_img = dest_img.replace(k,v)
    for k,v in REPO_REPLACE_RULE2.items():
        dest_img = dest_img.replace(k,v)
    for k,v in INTERNAL_NETWORK.items():
        dest_img = dest_img.replace(k,v)


    cmd = SKEPO_CMD + " sync --src docker --dest docker --dest-tls-verify=false --dest-creds root:%s -f oci %s %s" %(REGISTRY_PASSWORD,src_img,dest_img)
#   print(src_img)
#   print(dest_img)
#   print(cmd)
    return cmd

def main():
    lines = []
    with open("mirror.txt") as f:
        lines = f.readlines()
    sync_cmds = []
    for l in lines:
        sync_cmds.append(skepo_sync_cmd(l)) 
    random.shuffle(sync_cmds)
    for c in sync_cmds:
        print(c)
        os.system(c)

if __name__ == "__main__":
    # execute only if run as a script
    main()