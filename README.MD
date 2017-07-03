# Overview 

This container serves as a sandbox for backdoor access via SSH. This container can give you a CLI prompt on demand in a clean alpine linux base environment with the following packaged pre-installed : 

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

> **NOTE:** This container monitors when user(s) log onto the container. When a user logs in for the first time, it is noted and when no other user(s) are logged in after initial session, the container exits. A new container can the be run for a fresh environment when deployed though container orchrstration. This allows for a clean sanbox environment each time. Employ the equviliant of "force pull" with your orchestrator to get updated version of your sandbox image upon each run.

# Usage

Run the following command to start the container in a standalone dockerhost.

```
docker run -dt \
--privileged \
--name=backdoor  \
-p 222:22 \
-v /var/storage:/data:rw \
-v config:~/.kube/config:r0 \
mayankt/backdoor:dind
```

## Breakdown

`--privileged` The privileged flag gives all capabilities to the container, and it also lifts all the limitations enforced by the device cgroup controller. In other words, the container can then do almost everything that the host can do.

`--name=backdoor` This flag denotes the container's name "bacdoor" for easy identification

`-p 222:22` This flag maps the host port 222 to port 22 ont he container so one can SSH into the container from outside of the docker network. 

`-v /var/storage:/data:rw` This flag is a volume mount to denote the directory on the host at `/var/storage` is mapped to the directory in thec ontainer at `/data` so the contianer can access these files (`rw`) for persistent storage. 
  * This is an optional flag if you would perfer persistent storage on the host through the container. Without this flag the data is ephemeral and lost when the container is terminated. 

`-v /kube/config:/home/admin/.kube/config:ro` This flag denotes a file map of the file `/kube/config` on the local host to the file `/home/admin/.kube/config` on the container. This map allows for read only access (`ro`) to the kube config file to manage a kubernetes cluster.
  * This is an optional flag if you would not like to import a kube config file on the host into the container.

# SSH Access

Run this command within this git directory to SSH into the deployed container: 

`ssh -p 222 -i /keys/admin/id_rsa admin@localhost`

> It can be handy when running these containers to mount a volume locally on the container at `/data` to a NFS or network share mounted on the underlying host. This will allow for storing persistence data.

# Rancher Stack 

Included is a `rancher-compose.yml` file that I use to define my stack in a cattle environment. It has a HAProxy LB infront to load balance SSH requests on port 22 and exposes the port 222 on the host for exernal access to the fleet of backdoor contianer services. One thing to do it to figure out a way to terminate and remove the container after it stops (upon user logg off) and force pull a new container to maintaine active pool of backdoor containers. This compose file is still a work in progress.  