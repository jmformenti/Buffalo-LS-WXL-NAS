#!/bin/sh
# fetch-packages.sh - download the Optware bootstrap + NFS packages from the
# Wayback Machine, because ipkg.nslu2-linux.org is no longer reliable.
# Run on any machine with wget or curl, then copy the directory to the NAS.
#
# Usage: ./fetch-packages.sh [destdir]        (default: ./buffalo)
#        WITH_EXTRAS=1 ./fetch-packages.sh    also fetch openssh + nmap and their deps
set -e
DEST=${1:-buffalo}
FEED=http://ipkg.nslu2-linux.org/feeds/optware/cs05q3armel/cross/stable
# "id_" asks the Wayback Machine for the original bytes, unmodified
WB=http://web.archive.org/web/20250716190531id_
WB_BOOT=http://web.archive.org/web/20260305034506id_

# NFS needs only these two (neither has dependencies)
PKGS="portmap_4-5_arm.ipk unfs3_0.9.22-1_arm.ipk"
# optional: openssh (needs openssl, zlib) and nmap (needs libpcap openssl pcre libstdc++ lua; lua needs readline ncurses)
[ -n "$WITH_EXTRAS" ] && PKGS="$PKGS openssh_5.9p1-1_arm.ipk openssl_0.9.7m-6_arm.ipk zlib_1.2.5-1_arm.ipk \
  nmap_5.35DC1-3_arm.ipk libpcap_1.3.0-1_arm.ipk pcre_8.31-1_arm.ipk libstdc++_6.0.3-6_arm.ipk \
  lua_5.1.5-1_arm.ipk readline_6.1-2_arm.ipk ncurses_5.7-3_arm.ipk"

get() {  # get URL OUTFILE  (the Wayback Machine often answers 503 "busy": retry)
  i=0
  while [ $i -lt 6 ]; do
    i=$((i + 1))
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL -o "$2" "$1" && return 0
    else
      wget -q -O "$2" "$1" && return 0
    fi
    echo "  retry $i..." >&2; sleep $((i * 5))
  done
  echo "FAILED: $1" >&2; return 1
}

# known-good md5 sums (from a working LinkStation install)
MD5S="bf797392071a5e49e4b9aed6513e27f8  lspro-bootstrap_1.2-7_arm.xsh
7a6557171b081dce392744705fbfbdd6  portmap_4-5_arm.ipk
7b7c9efe7431f327cc88213f85e3ed1a  unfs3_0.9.22-1_arm.ipk
99b9b4f710884d9d13cc640154d47375  openssh_5.9p1-1_arm.ipk
1dfe557b94ad5d3f7d72e919532b5552  openssl_0.9.7m-6_arm.ipk
68500926bfea881a3745af0d96b31664  zlib_1.2.5-1_arm.ipk
e8124b15aa2240188110eac8c2336d8d  nmap_5.35DC1-3_arm.ipk
adaf1f48b9860e9f550a23d77910ef6c  libpcap_1.3.0-1_arm.ipk
926221791edffec685d28cb665fd1189  pcre_8.31-1_arm.ipk
aa84d9e1559e5b176500bdb71d7479df  libstdc++_6.0.3-6_arm.ipk
17bbc9b730627874df008647d483249d  lua_5.1.5-1_arm.ipk
c2aeba283de300642f6562c939ded931  readline_6.1-2_arm.ipk
975de41ecf26232e80f06ae81d9c7e45  ncurses_5.7-3_arm.ipk"

mkdir -p "$DEST"
echo "bootstrap: lspro-bootstrap_1.2-7_arm.xsh"
get "$WB_BOOT/$FEED/lspro-bootstrap_1.2-7_arm.xsh" "$DEST/lspro-bootstrap_1.2-7_arm.xsh"
for p in $PKGS; do
  echo "package:   $p"
  get "$WB/$FEED/$p" "$DEST/$p"
done
echo
echo "Verifying md5 sums..."
( cd "$DEST" && for f in *; do echo "$MD5S" | grep "  $f\$"; done | md5sum -c - ) || { echo "CHECKSUM MISMATCH, do not install" >&2; exit 1; }
echo
echo "Done. Copy '$DEST' to the NAS, e.g.:"
echo "  scp -r $DEST root@<nas-ip>:/root/"
