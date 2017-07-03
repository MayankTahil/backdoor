FROM docker:stable-dind 

# docker run --privileged --name=dind --storage-driver=vfs -dt -v ./data:/data -v config:~/.kube/config docker:stable-dind ; docker exec -it dind /bin/bash

RUN apk add --no-cache \
 sudo \
 curl \
 git \
 screen \
 htop \
 openssh \
 autossh \
 bash-completion \
 nano \
 tcpdump \
 coreutils && \
 # Generate host keys for sshd
 /usr/bin/ssh-keygen -A

RUN /usr/bin/ssh-keygen -A

# Install kubctl in the contianer
WORKDIR /usr/local/bin/
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl ; \
 chmod +x ./kubectl ; \
 mv ./kubectl /usr/local/bin/kubectl ; \
 mkdir -p /home/admin/.kube ; \
 touch /home/admin/.kube/config ; \
 mkdir -p /home/user/.kube ; \
 touch /home/admin/.kube/config

# Set container to be a SSH host with pre-seeded SSH keys from git project and prohibit root logon.
RUN mkdir /var/run/sshd && mkdir /data && mkdir /keys ; \
 echo 'root:screencast' | chpasswd ; \
 sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/shadow ; \
 echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

ENV NOTVISIBLE "in users profile"   
RUN echo "export VISIBLE=now" >> /etc/profile && export PATH=$PATH:/usr/sbin

#Add unlocked guest "user" (non-sudo) and retain keys in /keys
COPY ./keys /keys
RUN adduser -D user ; \
 mkdir -p /home/user/.ssh ; \
 touch /home/user/.ssh/authorized_keys ; \
 cat /keys/user/id_rsa.pub > /home/user/.ssh/authorized_keys ; \
 sed -i 's/user:!:17350:0:99999:7:::/user::17350:0:99999:7:::/' /etc/shadow

# Add unlocked user "admin" (sudo) and no ssh keys are retained.
RUN adduser -D admin ; \
 echo "admin            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers ; \
 mkdir /home/admin/.ssh ; \
 touch /home/admin/.ssh/authorized_keys ; \
 cat /keys/admin/id_rsa.pub > /home/admin/.ssh/authorized_keys ; \
 sed -i 's/admin:!:17350:0:99999:7:::/admin::17350:0:99999:7:::/' /etc/shadow ; \
 rm -rf /keys/admin

COPY ./infinite.sh /tmp/infinite.sh

WORKDIR /data

EXPOSE 22
CMD /tmp/infinite.sh

