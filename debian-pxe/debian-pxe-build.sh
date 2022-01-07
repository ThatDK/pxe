###WARNING
###TEST VERSION

#Written by Edward Dembecki
#Writted for Debian based ditributions
#Must run as root
# Checking install is run as root.
if [ $(whoami) = "root" ]; then
	echo "Install running as root. Ok."
else
	echo "Install script needs to run as root. FAILED: Running as user  "
	exit 1
fi

BASEDIR=$(dirname $0)
if [ ${PWD} = "${BASEDIR}" ]; then
	echo "Running from matching directory. Ok."
else
	echo "Must run from matching directory. FAILED."
	exit 1
fi

#Copying files to /root
cp ../

#Install tftpd
apt-get install tftpd-hpa -y

#Define tftp directory
rm /etc/default/tftpd-hpa
echo "# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"" >> /etc/default/tftpd-hpa

#Build directory structure
mkdir /tftpboot
cd /tftpboot
mkdir distros BIOS UEFI kickstart pxelinux.cfg
cd /tftpboot/distros
mkdir centos7 centos8 debian9 debian10 debain11 rhel7 rhel8 rhel9 iso
cd /tftpboot/kickstart
mkdir centos7 centos8 debian9 debian10 debain11 rhel7 rhel8 rhel9
mkdir /tftpboot/BIOS/pxelinux.cfg
mkdir /tftpboot/UEFI/pxelinux.cfg

#Pull ISOs
cd /tftpboot/distros/iso/
wget https://mirror.web-ster.com/centos/8.5.2111/isos/x86_64/CentOS-8.5.2111-x86_64-dvd1.iso
wget http://mirrors.gigenet.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso
wget https://cdimage.debian.org/cdimage/archive/11.2.0/amd64/iso-dvd/debian-11.2.0-amd64-DVD-1.iso
wget https://cdimage.debian.org/cdimage/archive/10.11.0/amd64/iso-dvd/debian-10.11.0-amd64-DVD-1.iso
wget https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso
wget https://downloads.freepbxdistro.org/ISO/SNG7-PBX-64bit-2104-1.iso
wget https://access.cdn.redhat.com/content/origin/files/sha256/19/19d653ce2f04f202e79773a0cbeda82070e7527557e814ebbce658773fbe8191/rhel-server-7.9-x86_64-dvd.iso?_auth_=1641414827_a99e99827d3da68aa35593e6e935f28c
wget https://access.cdn.redhat.com/content/origin/files/sha256/1f/1f78e705cd1d8897a05afa060f77d81ed81ac141c2465d4763c0382aa96cadd0/rhel-8.5-x86_64-dvd.iso?_auth_=1641414865_aaa53a4297749608efeccfe729db8997

#Rename long, annoying rhel names
mv rhel-8.5* rhel-8.5-x86_64-dvd.iso
mv rhel-server-7.9* rhel-server-7.9-x86_64-dvd.iso

#Build BIOS/UEFI menu structures
cp /root/syslinux-6.03/bios/com32/menu/menu.c32 /tftpboot/BIOS
cp /root/syslinux-6.03/bios/core/pxelinux.0 /tftpboot/BIOS
cp /root/syslinux-6.03/bios/com32/libutil/libutil.c32 /tftpboot/BIOS
cp /root/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 /tftpboot/BIOS
cp /root/syslinux-6.03/efi64/com32/elflink/ldlinux/ldlinux.e64 /tftpboot/UEFI
cp /root/syslinux-6.03/efi64/libutil/libutil.c32 /tftpboot/UEFI
cp /root/syslinux-6.03/efi64/com32/menu/menu.c32 /tftpboot/UEFI
cp /root/syslinux-6.03/efi64/efi/syslinux.efi /tftpboot/UEFI

#PXE menu contents
echo "#PXE script written by Edward Dembecki
# Please do not edit pre-existing entries unless you know what you are doing
default menu.c32
prompt 0
timeout 0

MENU TITLE PXE Menu

LABEL Debian11
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/debian11/install.amd/linux
	initrd tftp://192.168.3.3/distros/debian11/install.amd/initrd.gz
	append vga=normal priority=high auto=true auto url=tftp://192.168.3.3/kickstart/debian11/preseed.cfg

LABEL Debian10
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/debian10/install.amd/linux
	initrd tftp://192.168.3.3/distros/debian10/install.amd/initrd.gz
	append vga=normal priority=high auto=true auto url=tftp://192.168.3.3/kickstart/debian10/preseed.cfg

LABEL Debian9
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/debian9/install.amd/linux
	initrd tftp://192.168.3.3/distros/debian9/install.amd/initrd.gz
	append vga=normal priority=high auto=true auto url=tftp://192.168.3.3/kickstart/debian9/preseed.cfg

MENU SEPARATOR

LABEL CentOS8
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/centos8/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/centos8/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/kickstart/centos8/ ks=http://192.168.3.3/kickstart/centos8/ks.cfg

LABEL CentOS7
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/centos7/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/centos7/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/kickstart/centos7/ ks=http://192.168.3.3/kickstart/centos7/ks.cfg

MENU SEPARATOR

#LABEL RedHat9
#	TEXT HELP Unseeded Installer
#	ENDTEXT
#	kernel tftp://192.168.3.3/distros/rhel9/images/pxeboot/vmlinuz
#	initrd tftp://192.168.3.3/distros/rhel9/images/pxeboot/initrd.img
#	append vga=normal priority=high method=http://192.168.3.3/distros/rhel9/ 
#ks=http://192.168.3.3/kickstart/rhel9/ks.cfg

LABEL RedHat8
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/rhel8/isolinux/vmlinuz
	initrd tftp://192.168.3.3/distros/rhel8/isolinux/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/rhel8/ ks=http://192.168.3.3/kickstart/rhel8/ks.cfg

LABEL RedHat7
	TEXT HELP Unseeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/rhel7/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/rhel7/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/rhel7/ ks=http://192.168.3.3/kickstart/rhel7/ks.cfg

MENU SEPARATOR

LABEL FreePBX
	TEXT HELP Unseeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/freepbx/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/freepbx/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/freepbx/ ks=http://192.168.3.3/kickstart/freepbx/ks.cfg" >> /tftpboot/pxelinux.cfg/default

#Unpack ISOs
cd /tftpboot/distros/iso

mount CentOS-8.5.2111-x86_64-dvd1.iso /mnt
cp -r /mnt/* /tftpboot/distros/centos8
umount /mnt

mount CentOS-7-x86_64-DVD-2009.iso /mnt
cp -r /mnt/* /tftpboot/distros/centos7
umount /mnt

mount debian-9.13.0-amd64-DVD-1.iso /mnt
cp -r /mnt/* /tftpboot/distros/debian9
umount /mnt

mount debian-10.11.0-amd64-DVD-1.iso /mnt
cp -r /mnt/* /tftpboot/distros/debian10
umount /mnt

mount debian-11.2.0-amd64-DVD-1.iso /mnt
cp -r /mnt/* /tftpboot/distros/debian11
umount /mnt

mount rhel-server-7.9-x86_64-dvd.iso /mnt
cp -r /mnt/* /tftpboot/distros/rhel7
umount

mount rhel-8.5-x86_64-dvd.iso /mnt
cp -r /mnt/* /tftpboot/distros/rhel8
umount

#Download debian kernel/initrd
cd /tftpboot/distros/debian11/install.amd
rm initrd.gz
wget https://deb.debian.org/debian/dists/Debian11.2/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget https://deb.debian.org/debian/dists/Debian11.2/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

cd /tftpboot/distros/debian10/install.amd
rm initrd.gz
wget https://deb.debian.org/debian/dists/Debian10.11/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget https://deb.debian.org/debian/dists/Debian10.11/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

cd /tftpboot/distros/debian9/install.amd
rm initrd.gz
wget https://deb.debian.org/debian/dists/Debian9.13/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget https://deb.debian.org/debian/dists/Debian9.13/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

#Build preseeds
cd /root
cp debian9/preseed.cfg /tftpboot/kickstart/debian9
cp debian10/preseed.cfg /tftpboot/kickstart/debian10
cp debian11/preseed.cfg /tftpboot/kickstart/debian11
cp centos7/ks.cfg /tftpboot/kickstart/centos7
cp centos8/ks.cfg /tftpboot/kickstart/centos8
cp rhel7/ks.cfg /tftpboot/kickstart/rhel7
cp rhel8/ks.cfg /tftpboot/kickstart/rhel8

#Install DHCP server
apt-get install isc-dhcp-server -y
cd /root
cp dhcpd.conf /etc/dhcp/dhcpd.conf


#Build http
apt-get install apache2 -y

#Create links
cd /var/www/html
ln -s /tftpboot/* /var/www/html
rm index.html

cd /tftpboot/BIOS/pxelinux.cfg/
ln -s ../../pxelinux.cfg/default .
cd /tftpboot/UEFI/pxelinux.cfg/
ln -s ../../pxelinux.cfg/default .

#Warning
echo "WARNING: You will need to specify the DHCP interface in /etc/default/isc-dhcp-server"
echo "Info: You will need to change the IP address to match your server within the following files
/tftpboot/pxelinux.cfg/default
/etc/dhcp/dhcpd.conf
/tftpboot/kickstart/*"
echo "Info: You will need to change the passwords (currently hashed) within the /tftpboot/kickstart files"
