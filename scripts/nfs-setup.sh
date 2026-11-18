#!/bin/sh
# nfs-setup.sh - (re)install the user-space NFS server from local .ipk files
# and start it. Safe to run repeatedly. Needs no internet access.
#
# Expects (on the NAS):
#   /root/buffalo/*.ipk                       packages from fetch-packages.sh
#   /root/buffalo/lspro-bootstrap_1.2-7_arm.xsh
# Edit EXPORTS for your shares and LAN.
PKGDIR=/root/buffalo

# 1. ipkg itself comes from the bootstrap; only run it if ipkg is missing
if [ ! -x /opt/bin/ipkg ]; then
  ( cd /tmp && sh "$PKGDIR/lspro-bootstrap_1.2-7_arm.xsh" )
fi

# 2. install every local package (already-installed ones are skipped)
/opt/bin/ipkg install "$PKGDIR"/*.ipk < /dev/null

# 3. exports. Every path MUST exist: unfsd fails with NO error message if one is wrong
#    (e.g. after renaming a share in the Buffalo web UI).
cat > /opt/etc/exports <<EOX
/mnt/array1/share1 192.168.1.0/24(rw,sync)
/mnt/array1/share2 192.168.1.0/24(rw,sync)
EOX

# 4. start portmap first, then unfsd
/opt/etc/init.d/S55portmap
/opt/etc/init.d/S56unfsd
