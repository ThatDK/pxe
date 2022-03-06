###WARNING
###TEST VERSION

#Written by Edward Dembecki
#Must run as root

#Dowloading syslinux
echo 'Downloading syslinux'
cd needed-files
wget --no-check-certificate https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.03/syslinux-6.03-pre9.tar.gz

#Unpacking syslinux
echo 'Unpacking'
tar -xvzf syslinux-6.03-pre9.tar.gz
cd ..

#Checking for needed files
if [ $(ls needed-files | grep dhcpd.conf) = "dhcpd.conf" ] &&\
[ $(ls needed-files | grep syslinux-6.03*) "syslinux-6.03*" ]; then
	echo "Setup files found."
else
	echo "Failed to locate needed files."
        exit 1
fi

#Checking install is run as root.
if [ $(whoami) = "root" ]; then
	echo "Install running as root. Ok."
else
	echo "Install script needs to run as root. FAILED: Running as user"
	exit 1
fi

#Checking directory
if [ ${PWD} = "/root" ]; then
	echo "Running from /root directory. Ok."
else
	echo "Must run from /root directory. FAILED."
	exit 1
fi

#Checking distro
if [ "$(ls /etc | grep debian_version)" = "debian_version" ]; then
	echo "Debian distro detected."
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
mkdir centos7 centos8 debian9 debian10 debian11 freepbx iso
cd /tftpboot/kickstart
mkdir centos7 centos8 debian9 debian10 debian11 freepbx
mkdir /tftpboot/BIOS/pxelinux.cfg
mkdir /tftpboot/UEFI/pxelinux.cfg

#Pull ISOs
cd /tftpboot/distros/iso/
wget https://mirror.web-ster.com/centos/8.5.2111/isos/x86_64/CentOS-8.5.2111-x86_64-dvd1.iso
wget http://mirrors.gigenet.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso
wget https://cdimage.debian.org/cdimage/archive/11.1.0/amd64/iso-dvd/debian-11.1.0-amd64-DVD-1.iso
wget https://cdimage.debian.org/cdimage/archive/10.11.0/amd64/iso-dvd/debian-10.11.0-amd64-DVD-1.iso
wget https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso
wget https://downloads.freepbxdistro.org/ISO/SNG7-PBX-64bit-2104-1.iso

#Build BIOS/UEFI menu structures
cp /root/needed-files/syslinux-6.03/bios/com32/menu/menu.c32 /tftpboot/BIOS
cp /root/needed-files/syslinux-6.03/bios/core/pxelinux.0 /tftpboot/BIOS
cp /root/needed-files/syslinux-6.03/bios/com32/libutil/libutil.c32 /tftpboot/BIOS
cp /root/needed-files/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 /tftpboot/BIOS
cp /root/needed-files/syslinux-6.03/efi64/com32/elflink/ldlinux/ldlinux.e64 /tftpboot/UEFI
cp /root/needed-files/syslinux-6.03/efi64/com32/libutil/libutil.c32 /tftpboot/UEFI
cp /root/needed-files/syslinux-6.03/efi64/com32/menu/menu.c32 /tftpboot/UEFI
cp /root/needed-files/syslinux-6.03/efi64/efi/syslinux.efi /tftpboot/UEFI

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
	append vga=normal priority=high
#auto=true auto url=tftp://192.168.3.3/kickstart/debian11/preseed.cfg

LABEL Debian10
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/debian10/install.amd/linux
	initrd tftp://192.168.3.3/distros/debian10/install.amd/initrd.gz
	append vga=normal priority=high
#auto=true auto url=tftp://192.168.3.3/kickstart/debian10/preseed.cfg

LABEL Debian9
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/debian9/install.amd/linux
	initrd tftp://192.168.3.3/distros/debian9/install.amd/initrd.gz
	append vga=normal priority=high
#auto=true auto url=tftp://192.168.3.3/kickstart/debian9/preseed.cfg

MENU SEPARATOR

LABEL CentOS8
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/centos8/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/centos8/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/centos8/
#ks=http://192.168.3.3/kickstart/centos8/ks.cfg

LABEL CentOS7
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/centos7/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/centos7/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/centos7/
#ks=http://192.168.3.3/kickstart/centos7/ks.cfg

MENU SEPARATOR

LABEL FreePBX
	TEXT HELP Unseeded Installer
	ENDTEXT
	kernel tftp://192.168.3.3/distros/freepbx/images/pxeboot/vmlinuz
	initrd tftp://192.168.3.3/distros/freepbx/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://192.168.3.3/distros/freepbx/
#ks=http://192.168.3.3/kickstart/freepbx/ks.cfg" >> /tftpboot/pxelinux.cfg/default

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

mount debian-11.1.0-amd64-DVD-1.iso /mnt
cp -r /mnt/* /tftpboot/distros/debian11
umount /mnt

#Download debian kernel/initrd
cd /tftpboot/distros/debian11/install.amd/
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
cp needed-files/debian9/preseed.cfg /tftpboot/kickstart/debian9
cp needed-files/debian10/preseed.cfg /tftpboot/kickstart/debian10
cp needed-files/debian11/preseed.cfg /tftpboot/kickstart/debian11
cp needed-files/centos7/ks.cfg /tftpboot/kickstart/centos7
cp needed-files/centos8/ks.cfg /tftpboot/kickstart/centos8
cp needed-files/freepbx/ks.cfg /tftpboot/kickstart/freepbx

#Install DHCP server
apt-get install isc-dhcp-server -y
cd /root
cp needed-files/dhcpd.conf /etc/dhcp/dhcpd.conf


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

echo "#Make sure to change the IPs to the IP of your system." > /etc/dhcp/dhcpd.conf
nano /etc/dhcp/dhcpd.conf
echo "#Make sure to change the IPs to the IP of your system." > /tftpboot/pxelinux.cfg/default
nano /tftpboot/pxelinux.cfg/default

#Restart needed services
systemctl restrt tftp-hpa.service
systemctl restart apache*


#Warning
echo "Info: You will need to change the IP address to match your server within the kickstart files
/tftpboot/kickstart/*"
echo "Info: You will need to change the passwords (currently empty) within the /tftpboot/kickstart files"
	exit 1

else if [ $(ls /etc | grep redhat-release) = "redhat-release" ]; then
	echo "Rhel distro detected. Temporary Failure while developing"
	exit 1
else
	echo "Unknown version. FAILED"
	exit 1
fi
