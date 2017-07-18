# Overview 

This container serves as a sandbox for backdoor access via SSH. This container can give you a CLI prompt on demand in a clean [dind](https://hub.docker.com/_/docker/) base environment with the following packaged pre-installed: 

>Within this container, end users can run docker containers for testing and isolated on demand development. There are also utilities built in to manage kubernetes clusters as well.

* [docker](https://hub.docker.com/_/docker/) (runs within the backdoor docker container itself)
* sudo
* curl
* wget
* git
* nano
* screen
* htop
* s3cmd
* openssh-server
* ping
* tcpdump
* nslookup 
* telnet
* kubectl

> **NOTE:** This container is ideally supposed to monitor when user(s) log onto the container. This feature will soon be re-implemented soon in the next release. Ideally, when a user logs in for the first time, it is noted by a daemon service and when no other user(s) are logged in after initial session, the container exits. A new container can the be run for a fresh environment when deployed though container orchrstration. This allows for a clean sandbox environment each time. Employ the equviliant of "force pull" with your orchestrator to get updated version of your sandbox image upon each run.

# Build

You can pull this contianer from dockerhub (not reocmended because it comes pre-seeded with SSH keys found in this public repo for user `admin` and `user`) for quick testing or you can build the image yourself with your own private and public keys for user `admin` and `user`. 

To buid your backdoor container, execute the following steps. It is assumed each step begins at the parent directory where you cloned this repository. 

## Step 1: 

Clone this repository to your local host:
`git clone https://github.com/MayankTahil/backdoor.git`

## Step 2: 

Put your own private and public keys for both users that you can ssh into. 

Run the following commands: 

`cd ./backdoor/keys/admin`

`rm -rf ./*` 

[`ssh-keygen -t rsa -b 4096 -C "admin@domain.lab"`](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

and do the same for the other user:

`cd ./backdoor/keys/user`

`rm -rf ./*`

[`ssh-keygen -t rsa -b 4096 -C "user@domain.lab"`](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

> **NOTE:** Save these keys, particularly the private keys in a safe location! You will require these keys to SSH into the backdoor container.

## Step 3: 

Build your docker image by executing the following command: 

`cd ./backdoor`

`docker build -t mayankt/backdoor .`

# Usage

Run the following command to start the container in a standalone dockerhost.

```
docker run -dt \
--privileged \
--name=backdoor  \
-p 222:22 \
-v /var/storage:/data:rw \
-v Local/.kube/config:/kube/config:ro \
mayankt/backdoor:stable
```

## Breakdown

`--privileged` The privileged flag gives all capabilities to the container, and it also lifts all the limitations enforced by the device cgroup controller. In other words, the container can then do almost everything that the host can do.

`--name=backdoor` This flag denotes the container's name "bacdoor" for easy identification

`-p 222:22` This flag maps the host port 222 to port 22 ont he container so one can SSH into the container from outside of the docker network. 

`-v /var/storage:/data:rw` **Optional** This flag is a volume mount to denote the directory on the host at `/var/storage` is mapped to the directory in the container at `/data` so the container can access these files (`rw`) for persistent storage. 
  * This is an optional flag if you would prefer persistent storage on the host through the container. Without this flag the data is ephemeral and lost when the container is terminated. 

`-v Local/.kube/config:/kube/config:ro` **Optional** This flag denotes a file map of kubectl's config file `/Local/.kube/config` on the local host to the file `/kube/config` on the container. This map allows for read only access (`ro`) to the kube config file to manage a kubernetes cluster by any user logged into the container.
  * This is an optional flag if you would not like to import a kube config file into the container to manage a kubernetes cluster. 

# SSH Access

Run this command within this git directory to SSH into the deployed container: 

`ssh -p 222 -i /keys/admin/id_rsa admin@localhost`

* **admin** user is part of sudoers and root therfore can run commands like "docker..."

or 

`ssh -p 222 -i /keys/user/id_rsa user@localhost`

* **user** user is guest user with limited privileges and it cannot run commands like "docker..."


# Rancher Stack 

Included is a `rancher-compose.yml` file that I use to define my stack in a cattle environment. It has a HAProxy LB infront to load balance SSH requests on port 22 and exposes the port 222 on the host for exernal access to the fleet of backdoor contianer services. One thing to do it to figure out a way to terminate and remove the container after it stops (upon user logg off) and force pull a new container to maintaine active pool of backdoor containers. This compose file is still a work in progress.  