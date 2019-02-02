# backup-remote

setup script for rsync backup client.

:warning: before setting up this backup client, setup the [backup-server](https://github.com/kedamaDQ/backup-server/blob/create_readme/README.md)

## depends on

- rsync
- sudo
- rbash

## setup

### setup environment for backup-remote

setup into /root as root.

```
$ su -
```

clone scripts from github.

```
# git clone https://github.com/kedamaDQ/backup-remote.git
```

change directory into script root.

```
# cd ~/backup-remote
```

run setup script to create backup client user and its environment. `<username>` is user account which uses to access from backup server with ssh. see: [set user name for remote servers](https://github.com/kedamaDQ/backup-remote/edit/master/README.md#setup-scripts) `<username>` MUST make to same as setting `SSH_USER` on backup-server.

```
# ./setup.sh <username>
```

if no probrem, outputs are following:

```
found rsync: /usr/bin/rsync
found sudo: /usr/bin/sudo
found rbash: /bin/rbash
found clear: /usr/bin/clear
================================================================================
1. add following line into '/etc/sudoers' with visudo command or create drop-in
   file that includes following line into '/etc/sudoers.d/<username>'.

   <username> ALL=(root) NOPASSWD:/home/<username>/bin/rsync

2. put 'authorized_keys' file into '/home/<username>/.ssh/'.
   as much as possible, the file should includes 'from' host settings like
   following:

   from="<ipaddr.of.backup.server>"

   then, change owner of '.ssh' directory to root.

   chown -R root:root /home/<username>/.ssh/*

3. change 'PermitUserEnvironment' setting of '/etc/ssh/sshd_config' to 'yes'.

   PermitUserEnvironment yes

4. append settings for <username> to end of '/etc/ssh/sshd_config'.

   Match User <username>
     PasswordAuthentication no
     PubkeyAuthentication yes
     X11Forwarding no
     AllowAgentForwarding no
     AllowTcpForwarding no
     PermitTunnel no
     PermitUserRc no
     PermitTTY no

5. restart sshd.

   systemctl restart sshd

   or

   rc-service sshd restart

================================================================================
```

### add backup user to sudoers

```
# echo '<username> ALL=(root) NOPASSWD:/home/<username>/bin/rsync' > /etc/sudoers.d/<username>
```

### set authorized_keys to access from backup server

open `authorized_keys` with your editor.

```
# vi /home/<username>/.ssh/authorized_keys
```

append line for ssh access from backup server.

```
from="ip.adr.of.svr" ssh-rsa ABCDABCD....
```

ssh public key was already created name like `id_rsa_rsync.pub` in `/root/.ssh/` on backup server. see: [https://github.com/kedamaDQ/backup-server/blob/create_readme/README.md#create-ssh-key-pair](create ssh key pair)

in this step:

- copy a line from `id_rsa_rsync.pub` on backup server and paste the line into `authorized_keys`
- append `from="ip.adr.of svr"` into start of the pasted line as much as possible.

### change sshd settings

open `sshd_config` with your editor.

```
# vi /etc/ssh/sshd_config
```

change `PermitUserEnvironment` to `yes`

```
PermitUserEnvironment yes
```

and then, append settings for <username>.
  
```
   Match User <username>
     PasswordAuthentication no
     PubkeyAuthentication yes
     X11Forwarding no
     AllowAgentForwarding no
     AllowTcpForwarding no
     PermitTunnel no
     PermitUserRc no
     PermitTTY no
```

check syntax of `sshd_config`

```
# sshd -t
```

restart sshd.

```
# systemctl restart sshd
```

or

```
# /etc/init.d/sshd restart
```
