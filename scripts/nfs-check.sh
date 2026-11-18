#!/bin/sh
# nfs-check.sh - if unfsd is not running, rebuild/start NFS with /root/nfs-setup.sh.
# Install on the NAS as /root/nfs-check.sh and run it from root's crontab every minute:
#
#   * * * * * /bin/sh /root/nfs-check.sh
#
# Why cron and not @reboot: the LinkStation firmware ships BusyBox 1.7 crond, which has
# no @reboot support. Cron also runs with a minimal PATH, so set it here.
PATH=/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH
touch /tmp/nfs-check.last   # heartbeat: shows cron is running this
if ! ps | grep -q "[u]nfsd"; then
    logger -t nfs-check "unfsd not running, running nfs-setup.sh"
    /root/nfs-setup.sh >> /root/nfs-check.log 2>&1
fi
