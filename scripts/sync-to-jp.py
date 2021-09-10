import os

REPO_REPLACE_RULE = {
	"gcr.io":"gcr-jp.m.daocloud.io",
	"k8s.gcr.io":"k8s-gcr-jp.m.daocloud.io",
	"docker.io":"docker-jp.m.daocloud.io",
	"quay.io":"quay-jp.m.daocloud.io",
	"ghcr.io":"ghcr-jp.m.daocloud.io",
}


REGISTRY_PASSWORD = os.environ["REGISTRY_PASSWORD"]


SKEPO_CMD = "docker run -it quay.io/containers/skopeo:latest"
# SKEPO_CMD = "skepo" # RUN without docker

def skepo_sync_cmd(src_img):
	src_img = src_img.strip()
	dest_img = "/".join(src_img.split("/")[:-1])
	cmd = SKEPO_CMD + " sync --src docker --dest %s --dest-tls-verify=false --dest-creds root:%s -f oci %s" %(src_img,REGISTRY_PASSWORD,dest_img)
#	print(src_img)
#	print(dest_img)
#	print(cmd)
	return cmd

def main():
	lines = []
	with open("mirror.txt") as f:
		lines = f.readlines()
	sync_cmds = []
	for l in lines:
		sync_cmds.append(skepo_sync_cmd(l)) 
	for c in sync_cmds:
		os.system(c)

if __name__ == "__main__":
    # execute only if run as a script
    main()