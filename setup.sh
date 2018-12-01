#
# create user account for backup and setup environment.
#

# check running user
if [[ "$(whoami)" != 'root' ]]; then
  echo "need to run as root."
  exit 1
fi

# check argument
if [[ -z ${1} ]]; then
  echo "invalid arguments."
  echo "usage: bash ${0} username [base-directory(default: /home)]"
  exit 2
fi
BACKUP_RUNNER=${1}

# home directory base
BASE_DIR=${2:-'/home'}
if [[ ! -d "${BASE_DIR}" ]]; then
  echo "base directory is not a directory: ${BASE_DIR}"
  echo "usage: bash ${0} username [base-directory(default: /home)]"
  exit 2
fi

# check rsync
RSYNC_CMD=$(which rsync)
if [[ -z "${RSYNC_CMD}" ]]; then
  echo "rsync not available."
  exit 3
fi
echo "found rsync: ${RSYNC_CMD}"

# check sudo
SUDO_CMD=$(which sudo)
if [[ -z "${SUDO_CMD}" ]]; then
  echo "sudo not available."
  exit 4
fi
echo "found sudo: ${SUDO_CMD}"

# check rbash
RBASH_CMD=$(which rbash)
if [[ -z "${RBASH_CMD}" ]]; then
  echo "rbash not available."
  echo "run to create rbash:"
  echo "  ln -s $(which bash) $(dirname $(which bash))/rbash"
  exit 5
fi
echo "found rbash: ${RBASH_CMD}"
HOME_DIR="${BASE_DIR}/${BACKUP_RUNNER}"

# create user and create group which is same name as user
useradd \
  --create-home --user-group --home-dir ${HOME_DIR} --shell ${RBASH_CMD}\
  --comment 'remote backup runner' ${BACKUP_RUNNER} 

if [[ ${?} -ne 0 ]]; then
  echo "failed to create user: ${BACKUP_RUNNER}"
  exit 6
fi

# create individual 'bin' directory
mkdir "${HOME_DIR}/bin"
chown root:root "${HOME_DIR}/bin"
chmod 755 "${HOME_DIR}/bin"

# create links which are allowed to execute for backup user
ln -s "${SUDO_CMD}" "${HOME_DIR}/bin/sudo"
ln -s "${RSYNC_CMD}" "${HOME_DIR}/bin/rsync"

# create links "clear" which is called by ".bash_logout" of some linux distribution
CLEAR_CMD=$(which clear)
if [[ ! -z "${CLEAR_CMD}" ]]; then
  echo "found clear: ${CLEAR_CMD}"
  ln -s "${CLEAR_CMD}" "${HOME_DIR}/bin/clear"
fi

# restrict the command search path and built in commands.
echo "export PATH=${HOME_DIR}/bin" >> "${HOME_DIR}/.bash_profile"
echo "enable -n kill" >> "${HOME_DIR}/.bash_profile"
echo "enable -n set" >> "${HOME_DIR}/.bash_profile"
echo "enable -n enable" >> "${HOME_DIR}/.bash_profile"
chown root:root "${HOME_DIR}/.bash_profile" "${HOME_DIR}/.bashrc"
chmod 644 "${HOME_DIR}/.bash_profile" "${HOME_DIR}/.bashrc"

# create .ssh
mkdir -p "${HOME_DIR}/.ssh"
echo "PATH=${HOME_DIR}/bin" > "${HOME_DIR}/.ssh/environment"
chown -R root:root "${HOME_DIR}/.ssh"

cat << EOD
================================================================================
1. add following line into '/etc/sudoers' with visudo command or create drop-in
   file that includes following line into '/etc/sudoers.d/${BACKUP_RUNNER}'.

   ${BACKUP_RUNNER} ALL=(root) NOPASSWD:${HOME_DIR}/bin/rsync

2. put 'authorized_keys' file into '${HOME_DIR}/.ssh/'.
   as much as possible, the file should includes 'from' host settings like
   following:

   from="<ipaddr.of.backup.server>"

   then, change owner of '.ssh' directory to root.

   chown -R root:root ${HOME_DIR}/.ssh

3. change 'PermitUserEnvironment' setting of '/etc/ssh/sshd_config' to 'yes'.

   PermitUserEnvironment yes

4. append settings for ${BACKUP_RUNNER} to end of '/etc/ssh/sshd_config'.

   Match User ${BACKUP_RUNNER}
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
EOD

exit 0
