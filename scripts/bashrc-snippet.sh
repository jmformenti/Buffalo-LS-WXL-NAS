# Append to /root/.bashrc on the NAS.
# Whenever root logs in (interactively, or from a cron job / monitoring script
# running "ssh root@nas <command>") and unfsd is not running, rebuild NFS.
if ! ps | grep -q '[u]nfsd'; then
   echo "NFS not running, setting up..."
   ~/nfs-setup.sh
fi
