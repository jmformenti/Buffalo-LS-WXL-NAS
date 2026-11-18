# Buffalo LS-WXL NAS

This document briefly describes how to install NFS on your buffalo device,
along with how to get remote root access, via SSH.

There are two systems involved here:

* My desktop system - which will mount the exports.
  * `192.168.1.160`
* The NAS device itself.
  * `192.168.1.4`


## Get Root

To get root on the device you can use the bundled `acp_commander.jar` command - of course you'll need a Java installation to do that.

Using `acp_commander.jar` you can execute arbitrary commands on the NAS, as `root`,  you just need to know the IP address of your NAS and the password for the `admin` user.

Add your details to the [nas](nas) script, then execute it like so:

    Using random connID value = 83E20F6293D2
    Using MAC: 106f3fe44e46
    Using target:	192.168.1.4/192.168.1.4
    Starting authentication procedure...
    Sending Discover packet...	
    Found:	kinton (/192.168.1.4) 	LS-WXL(KEITAI) (ID=00486) 	mac:     10:6F:3F:E4:4E:46	Firmware=  1.740	Key=2DFEBB60
    Trying to authenticate EnOneCmd...	ACP_STATE_OK
    Trying to authenticate with admin password...	ACP_STATE_OK
    > uptime
     21:25:59 up 2 min, load average: 1.28, 0.77, 0.30

    Changeing IP:	ACP_STATE_PASSWORD_ERROR

    Please note, that the current support for the change of the IP is currently very rudimentary.
    The IP has been set to the given, fixed IP. However DNS and gateway have not been set. Use the WebGUI to make appropriate settings.

Although in the end it fails, the command was able to run successfully. You can now examine the get-root script which will run a couple of commands:

* [root.sh](root.sh)
  * Change the `root` password to `ssh.pass`.
    * **NOTE**: This is the password you'll use for SSH, the `admin` webui login will remain unchanged.
  * Enable SFTP/SSH support.
  * Stop & start the `sshd` server


Once you have root you can login to your NAS via SSH and run commands
interactively, as you'd expect:

    $ ssh -o PreferredAuthentications=password -oKexAlgorithms=+diffie-hellman-group1-sha1 root@192.168.1.4
    root@192.168.1.4's password:

>**REMEMBER**: The `root.sh` script will have set the ssh-password to be `ssh.pass`.

>**NOTE**: The `PreferredAuthentications` option is needed to prevent keyboard-interactive authentication. 

    [root@kinton ~]# uptime
     21:35:37 up 12 min, load average: 0.16, 0.29, 0.28

    [root@kinton ~]# free
                  total         used         free       shared      buffers
     Mem:        117560        96772        20788            0         5424
     Swap:      1000432          500       999932
     Total:     1117992        97272      1020720

    [root@kinton ~]# uname -r
    3.3.4-88f6281

    [root@kinton ~]# cat /proc/mdstat
    Personalities : [linear] [raid0] [raid1] [raid6] [raid5] [raid4] 
    md2 : active raid1 sda6[0] sdb6[1]
              1938311340 blocks super 1.2 [2/2] [UU]
      
    md1 : active raid1 sda2[0] sdb2[1]
              4999156 blocks super 1.2 [2/2] [UU]
      
    md10 : active raid1 sda5[0] sdb5[1]
              1000436 blocks super 1.2 [2/2] [UU]
      
    md0 : active raid1 sda1[0] sdb1[1]
              1000384 blocks [2/2] [UU]
      
    unused devices: <none>


## Troubleshooting getting root

Check in `/etc/sshd_config` that exists only one parameter `PermitRootLogin`:

    [root@kinton ~]# cat /etc/sshd_config  | grep PermitRootLogin

In case exists two parameters, only keep `PermitRootLogin yes`.

Check if dns is configured:

    [root@kinton ~]# cat /etc/resolf.conf

If is empty, fill with dns servers, for example with [OpenDNS](https://www.opendns.com/):

    [root@kinton ~]# cat /etc/resolf.conf
    nameserver 208.67.222.222
    nameserver 208.67.220.220

Check date/time is correct:

    [root@kinton ~]# date
    Sat Dec 26 21:51:15 CET 2020

If it's not correct, update with:

    [root@kinton ~]# ntpdate -s -b ntp.jst.mfeed.ad.jp


## Install ipkg

> **Note:** `ipkg.nslu2-linux.org` is no longer reliably online. If the `wget` below fails, see
> [nslu2-linux.org is gone: installing from the Wayback Machine](#nslu2-linuxorg-is-gone-installing-from-the-wayback-machine-and-keeping-nfs-alive).

Install `ipkg` like so:

    cd /tmp
    wget http://ipkg.nslu2-linux.org/feeds/optware/cs05q3armel/cross/stable/lspro-bootstrap_1.2-7_arm.xsh
    sh ./lspro-bootstrap_1.2-7_arm.xsh

> **NOTE**: If this site disappears you can look at the `archive/` directory in this repository.

The `.xsh` script will boosttrap the system, by unpackaging a binary-archive embedded within itself, and then executing it.

To view the contents of the archive you can run this:

    # dd if=lspro-bootstrap_1.2-7_arm.xsh bs=201 skip=1 2>/dev/null| tar xz
    bootstrap/
    bootstrap/bootstrap.sh
    bootstrap/ipkg-opt.ipk
    bootstrap/ipkg.sh
    bootstrap/optware-bootstrap.ipk
    bootstrap/wget.ipk

> **NOTE**: Use `.. | tar xf` if you wish to unpack locally and read what will be executed.

When `./bootstrap/bootstrap.sh` is executed it will install the two bundled `.ipkg` files (giving `ipkg` itself, and `wget` which is used to download packages), and configure `ipkg`.

Once installed, configure variable `REAL_OPT_DIR` in `/etc/init.d/rc.optware` script with persistent directory created with ipkg installation, in my case `/mnt/array1/.optware`:

    [root@kinton ~]# cat /etc/init.d/rc.optware
    #! /bin/sh

    if test -z "${REAL_OPT_DIR}"; then
    # next line to be replaced according to OPTWARE_TARGET
    REAL_OPT_DIR=/mnt/array1/.optware
    fi
    ....

## Install NFS

Once you have `ipkg`, the package-manager, installed you can install things via:

    # ipkg update
    # ipkg install $name

To get the (user-space) NFS-server you'll run:

    # ipkg update
    # ipkg install unfs3

To configure your exports you need to edit the configuration file
`/opt/etc/exports`.  My example is this:

    /mnt/array1/backup	192.168.1.2(rw,sync,anonuid=1001,anongid=100)
    /mnt/array1/shared	192.168.1.2(rw,sync,anonuid=1001,anongid=100)

Once that file has been updated you'll need to restart NFS:

    /opt/etc/init.d/S56unfsd stop
    /opt/etc/init.d/S56unfsd start

>**NOTE**: We're explicitly installing the __user-space__ NFS server here.  My first attempt involved using the kernel-mode NFS server, via a third-party repository.  This failed to boot, effectively bricking the device neatly.  Recovering from that was a real pain, and something I have no wish to repeat!  (You need a third-party kernel because the default kernel contains zero NFS-modules.  Also doesn't contain a kernel `.config` file either.)
>**NOTE2**: Instead of unfsd3 you can install nfs-server, the main difference is that nfs-server implements NFS protocol version 2 which has a limitation to manage files until 2GB. The unfsd3 implements NFS protocol version 3.

## Troubleshooting with NFS

If NFS service is not started automatically when boots, add a last sleep line in `/opt/etc/init.d/S56unfsd`:

    root@kinton:/# cat /opt/etc/init.d/S56unfsd 
    #!/bin/sh

    if [ -n "`pidof unfsd`" ] ; then
        killall unfsd 2>/dev/null
    fi

    sleep 2
    /opt/sbin/unfsd -e /opt/etc/exports

    # If you no wait, the processes die
    sleep 5

## nslu2-linux.org is gone: installing from the Wayback Machine (and keeping NFS alive)

The Optware feed this guide downloads from (`ipkg.nslu2-linux.org`) has gone offline,
so `wget .../lspro-bootstrap_1.2-7_arm.xsh` and `ipkg update` / `ipkg install` no longer work
reliably. The packages are still in the Internet Archive's Wayback Machine. The steps below
fetch them once, keep them on the NAS, and install everything offline. A cron job then
rebuilds NFS by itself after the NAS reboots.

Tested on a LinkStation (firmware 1.75, kernel 3.3.4, armv5tel) with `unfs3 0.9.22-1`.

### 1. Download the packages (on any Linux/macOS machine)

Use [`scripts/fetch-packages.sh`](scripts/fetch-packages.sh). It downloads the bootstrap and the
packages from the Wayback Machine, retries when the archive answers `503`, and checks every
file against known-good md5 sums:

    ./scripts/fetch-packages.sh                  # bootstrap + portmap + unfs3 (all NFS needs)
    WITH_EXTRAS=1 ./scripts/fetch-packages.sh    # also openssh and nmap with their dependencies

NFS needs only two packages, and neither has dependencies:

| Package | Needed for | md5 |
|---|---|---|
| `lspro-bootstrap_1.2-7_arm.xsh` | `ipkg` itself | `bf797392071a5e49e4b9aed6513e27f8` |
| `portmap_4-5_arm.ipk` | NFS | `7a6557171b081dce392744705fbfbdd6` |
| `unfs3_0.9.22-1_arm.ipk` | NFS | `7b7c9efe7431f327cc88213f85e3ed1a` |
| `openssh_5.9p1-1_arm.ipk` (+ `openssl`, `zlib`) | optional | see script |
| `nmap_5.35DC1-3_arm.ipk` (+ `libpcap`, `openssl`, `pcre`, `libstdc++`, `lua`, `readline`, `ncurses`) | optional | see script |

The Wayback URLs have this form (`id_` returns the original file unmodified):

    http://web.archive.org/web/20250716190531id_/http://ipkg.nslu2-linux.org/feeds/optware/cs05q3armel/cross/stable/unfs3_0.9.22-1_arm.ipk

### 2. Copy them to the NAS

    scp -r buffalo root@<nas-ip>:/root/

Keeping the packages on the NAS (not on another server) means the NAS can reinstall
everything on its own, even if nothing else on the network is up.

### 3. Install and start NFS offline

Copy [`scripts/nfs-setup.sh`](scripts/nfs-setup.sh) to `/root/nfs-setup.sh` on the NAS, edit the
exports for your shares and LAN, and run it:

    chmod +x /root/nfs-setup.sh
    /root/nfs-setup.sh

It runs the bootstrap only if `ipkg` is missing, installs every local `.ipk`
(`ipkg install /root/buffalo/*.ipk`), writes `/opt/etc/exports`, and starts `S55portmap` and then
`S56unfsd`. It is safe to run again at any time.

> **Gotcha:** every path in `/opt/etc/exports` must exist. If one doesn't (for example after
> renaming a share in the Buffalo web UI), `unfsd` **fails without any error message**.
> Check with `showmount -e <nas-ip>` from another machine.

### 4. Bring NFS back automatically after a reboot

On these units NFS often does not survive a reboot or power cut, even though the firmware's
`rcS` runs `rc.optware` and so `S55portmap`/`S56unfsd` at boot (see *Troubleshooting with NFS*
above). Instead of relying on that, let cron check every minute and rebuild NFS when `unfsd` isn't
running. Copy [`scripts/nfs-check.sh`](scripts/nfs-check.sh) to `/root/nfs-check.sh` and add it to
root's crontab:

    chmod +x /root/nfs-check.sh
    crontab -l > /tmp/ct && echo '* * * * * /bin/sh /root/nfs-check.sh' >> /tmp/ct && crontab /tmp/ct

NFS is then back within about a minute of the NAS booting, with no other machine involved.
When it has to act, it logs to syslog (`nfs-check`) and to `/root/nfs-check.log`.
`/tmp/nfs-check.last` is touched on every run, so you can confirm cron is calling it.

> **Gotchas:**
> - `@reboot` does **not** work here. The firmware's crond is BusyBox 1.7 (2009), which predates
>   `@reboot` support, so the line is silently ignored.
> - cron runs with a minimal `PATH`. The script sets its own, so `ipkg`, `killall`, `pidof` and the
>   `/opt/etc/init.d` scripts are all found.
> - The Buffalo firmware may rewrite root's crontab when settings are changed in its web UI (unconfirmed).
>   If NFS stops coming back after a reboot, check `crontab -l` first.

### Tip: SSH into the NAS from a modern Linux client

The NAS runs an old OpenSSH that only offers `diffie-hellman-group1-sha1` and a 1024-bit RSA host key,
both of which current distributions (e.g. Fedora) refuse by default. In `~/.ssh/config`:

    Host buffalo-nas
        HostName <nas-ip>
        User root
        KexAlgorithms +diffie-hellman-group1-sha1
        HostKeyAlgorithms +ssh-rsa
        PubkeyAcceptedKeyTypes +ssh-rsa
        RequiredRSASize 1024

On Fedora/RHEL the system crypto policy also blocks SHA-1 inside OpenSSL ("error in libcrypto").
Allow it for this one command instead of system-wide, with a small OpenSSL config:

    # ~/.config/buffalo-nas/openssl-sha1.cnf
    openssl_conf = default_conf

    [default_conf]
    alg_section = evp_properties

    [evp_properties]
    rh-allow-sha1-signatures = yes

    OPENSSL_CONF=~/.config/buffalo-nas/openssl-sha1.cnf ssh buffalo-nas

## Testing NFS

From a local system in your LAN, with IP `192.168.1.160`, you should now
be able to list those exports:

    root@192.168.1.160:~# showmount -e 192.168.1.4
    Export list for 192.168.1.4:
    /mnt/array1/shared 192.168.1.2
    /mnt/array1/backup 192.168.1.2

## Mounting NFS Shares

This is what I did to mount the shares on 192.168.1.2:

    mkdir /mnt/shared
    mount  -t nfs 192.168.1.4:/mnt/array1/shared /mnt/shared

    mkdir /mnt/backup
    mount  -t nfs 192.168.1.4:/mnt/array1/backup /mnt/backup

All done.

