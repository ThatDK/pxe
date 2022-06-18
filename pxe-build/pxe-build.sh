###WARNING
###TEST VERSION

#Written by Edward Dembecki
#Must run as root

#Code to be tested later
#ip a | grep inet | tail -n 2 | head -n 1 > file.txt && grep -E -o\
# '((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' file.txt | head -n 1

##Setting variables
#path running from
a="${PWD}"
#netmask
b=$(ip a | grep $(hostname -I | cut -d " " -f1) | cut -d "/" -f2 | cut -d " " -f1)
#subnet
c=$(hostname -I | cut -d " " -f1 | cut -d "." -f1-3)
#IP
d=$(hostname -I | cut -d " " -f1)
#interface
f=$(ip a | grep BROADCAST,MULTICAST,UP | grep -v DOWN | grep -v NO-CARRIER | cut -d " " -f2 | cut -d ":" -f1 | head -n 1)

#Checking directory
#if [ ${PWD} = "/root/pxe-build" ]; then
#	echo "Running from /root/pxe-build directory. Ok."
#else
#	echo "Must run from /root/pxe-build directory. FAILED."
#	exit 1
#fi

#confirmation
echo "This script installs a TFTP server, DHCP server, and downloads several ISO files."
echo "Be careful when running this script if you already have a DHCP server running."
read -r -p "Do you still wish to run this script? (y/n) " e
if [ -z $e ] || [ n = $e ]
then
	exit 1
fi

#Checking install is run as root.
if [ $(whoami) = "root" ]; then
	echo "Install running as root. Ok."
else
	echo "Install needs root permissions. FAILED: Running as user"
	exit 1
fi

if [ "$b" = "1" ]; then b=128.0.0.0;
elif [ "$b" = "2" ]; then b=192.0.0.0;
elif [ "$b" = "3" ]; then b=224.0.0.0;
elif [ "$b" = "4" ]; then b=240.0.0.0;
elif [ "$b" = "5" ]; then b=248.0.0.0;
elif [ "$b" = "6" ]; then b=252.0.0.0;
elif [ "$b" = "7" ]; then b=254.0.0.0;
elif [ "$b" = "8" ]; then b=255.0.0.0;
elif [ "$b" = "9" ]; then b=255.128.0.0;
elif [ "$b" = "10" ]; then b=255.192.0.0;
elif [ "$b" = "11" ]; then b=255.224.0.0;
elif [ "$b" = "12" ]; then b=255.240.0.0;
elif [ "$b" = "13" ]; then b=255.248.0.0;
elif [ "$b" = "14" ]; then b=255.252.0.0;
elif [ "$b" = "15" ]; then b=255.254.0.0;
elif [ "$b" = "16" ]; then b=255.255.0.0;
elif [ "$b" = "17" ]; then b=255.255.128.0;
elif [ "$b" = "18" ]; then b=255.255.192.0;
elif [ "$b" = "19" ]; then b=255.255.224.0;
elif [ "$b" = "20" ]; then b=255.255.240.0;
elif [ "$b" = "21" ]; then b=255.255.248.0;
elif [ "$b" = "22" ]; then b=255.255.252.0;
elif [ "$b" = "23" ]; then b=255.255.254.0;
elif [ "$b" = "24" ]; then b=255.255.255.0;
elif [ "$b" = "25" ]; then b=255.255.255.128;
elif [ "$b" = "26" ]; then b=255.255.255.192;
elif [ "$b" = "27" ]; then b=255.255.255.224;
elif [ "$b" = "28" ]; then b=255.255.255.240;
elif [ "$b" = "29" ]; then b=255.255.255.248;
elif [ "$b" = "30" ]; then b=255.255.255.252;
elif [ "$b" = "31" ]; then b=255.255.255.254;
elif [ "$b" = "32" ]; then b=255.255.255.255;
else echo "Invalid CIDR Notation"; exit 1;
fi

#Dowloading syslinux
echo 'Downloading syslinux'
wget --no-check-certificate https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.03/syslinux-6.03-pre9.tar.gz -O $PATH/needed-files/

#Unpacking syslinux
echo 'Unpacking'
tar -xvzf syslinux-6.03-pre9.tar.gz >> /dev/null
rm syslinux-6.03-pre9.tar.gz

#Checking for needed files
if [ "$(ls $PATH/needed-files/debian | grep dhcpd.conf)" = "dhcpd.conf" ] &&\
[ "$(ls $PATH/needed-files | grep syslinux-6.03-pre9)" = "syslinux-6.03-pre9" ]; then
	echo "Setup files found."
else
	echo "Failed to locate needed files."
        exit 1
fi

#renaming syslinux
mv $PATH/needed-files/syslinux-6.03-pre9 $PATH/needed-files/syslinux-6.03

#Checking distro
if [ "$(ls /etc | grep debian_version)" = "debian_version" ]; then
	echo "Debian distro detected."
#Install tftpd/dhcp
apt-get install tftpd-hpa isc-dhcp-server apache2 -y


#Define tftp directory
rm /etc/default/tftpd-hpa
echo '# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"' >> /etc/default/tftpd-hpa

elif [ $(ls /etc | grep redhat-release) = "redhat-release" ]; then
	echo "Be careful. This distro's version is currently under development, and therefore is incomplete."
sleep 10s
#Disable selinux if not already
sed -i '7s/.*/SELINUX=disabled/' /etc/selinux/config

#Install tftp server
yum install tftp tftp-server dhcp httpd -y

#allow through firewalld
firewall-cmd --zone=public --add-service=tftp --permanent
firewall-cmd --reload

#move modified tftp files
cp $PATH/needed-files/rhel/tftp/* /usr/lib/systemd/system/
else
	echo "Unknown version. FAILED"
	exit 1
fi

if [ "$(ls /etc | grep debian_version)" = "debian_version" ]; then
	#Configure DHCP server Debian
	cp $PATH/needed-files/debian/dhcpd.conf /etc/dhcp/dhcpd.conf
elif [ $(ls /etc | grep redhat-release) = "redhat-release" ]; then
	#Configure DHCP server rhel
	cp $PATH/needed-files/rhel/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf
else
	exit 1
fi

sed -i "s/NETMASK/$b/g" /etc/dhcp/dhcpd.conf
sed -i "s/SUBNET/$c/g" /etc/dhcp/dhcpd.conf
sed -i "s/IP ADDRESS/$d/g" /etc/dhcp/dhcpd.conf
sed -i "s/INTERFACESv4=""/INTERFACESv4=$f/g" /etc/default/isc-dhcp-server && sed -i 's/""//g' /etc/default/isc-dhcp-server

#Build directory structure
mkdir /tftpboot
cd /tftpboot
mkdir distros BIOS UEFI kickstart pxelinux.cfg
cd /tftpboot/distros
mkdir centos7 debian9 debian10 debian11 freepbx iso
cd /tftpboot/kickstart
mkdir centos7 debian9 debian10 debian11 freepbx
mkdir /tftpboot/BIOS/pxelinux.cfg
mkdir /tftpboot/UEFI/pxelinux.cfg

#change permissions of tftp
chmod 755 /tftpboot

#Pull ISOs
cd /tftpboot/distros/iso/
wget --no-check-certificate http://mirrors.gigenet.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-DVD-2009.iso
wget --no-check-certificate https://cdimage.debian.org/cdimage/archive/11.1.0/amd64/iso-dvd/debian-11.1.0-amd64-DVD-1.iso
wget --no-check-certificate https://cdimage.debian.org/cdimage/archive/10.11.0/amd64/iso-dvd/debian-10.11.0-amd64-DVD-1.iso
wget --no-check-certificate https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso
wget --no-check-certificate https://downloads.freepbxdistro.org/ISO/SNG7-PBX-64bit-2104-1.iso

#Build BIOS/UEFI menu structures
cp $PATH/needed-files/syslinux-6.03/bios/com32/menu/menu.c32 /tftpboot/BIOS
cp $PATH/needed-files/syslinux-6.03/bios/core/pxelinux.0 /tftpboot/BIOS
cp $PATH/needed-files/syslinux-6.03/bios/com32/libutil/libutil.c32 /tftpboot/BIOS
cp $PATH/needed-files/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 /tftpboot/BIOS
cp $PATH/needed-files/syslinux-6.03/efi64/com32/elflink/ldlinux/ldlinux.e64 /tftpboot/UEFI
cp $PATH/needed-files/syslinux-6.03/efi64/com32/libutil/libutil.c32 /tftpboot/UEFI
cp $PATH/needed-files/syslinux-6.03/efi64/com32/menu/menu.c32 /tftpboot/UEFI
cp $PATH/needed-files/syslinux-6.03/efi64/efi/syslinux.efi /tftpboot/UEFI

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
	kernel tftp://$d/distros/debian11/install.amd/linux
	initrd tftp://$d/distros/debian11/install.amd/initrd.gz
	append vga=normal priority=high
#auto=true auto url=tftp://$d/kickstart/debian11/preseed.cfg

LABEL Debian10
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://$d/distros/debian10/install.amd/linux
	initrd tftp://$d/distros/debian10/install.amd/initrd.gz
	append vga=normal priority=high
#auto=true auto url=tftp://$d/kickstart/debian10/preseed.cfg

LABEL Debian9
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://$d/distros/debian9/install.amd/linux
	initrd tftp://$d/distros/debian9/install.amd/initrd.gz
	append vga=normal priority=high
#auto=true auto url=tftp://$d/kickstart/debian9/preseed.cfg

MENU SEPARATOR

LABEL CentOS7
	TEXT HELP Seeded Installer
	ENDTEXT
	kernel tftp://$d/distros/centos7/images/pxeboot/vmlinuz
	initrd tftp://$d/distros/centos7/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://$d/distros/centos7/
#ks=http://$d/kickstart/centos7/ks.cfg

MENU SEPARATOR

LABEL FreePBX
	TEXT HELP Unseeded Installer
	ENDTEXT
	kernel tftp://$d/distros/freepbx/images/pxeboot/vmlinuz
	initrd tftp://$d/distros/freepbx/images/pxeboot/initrd.img
	append vga=normal priority=high method=http://$d/distros/freepbx/
#ks=http://$d/kickstart/freepbx/ks.cfg" >> /tftpboot/pxelinux.cfg/default

#Unpack ISOs
cd /tftpboot/distros/iso

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
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian11.2/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian11.2/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

cd /tftpboot/distros/debian10/install.amd/
rm initrd.gz
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian10.11/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian10.11/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

cd /tftpboot/distros/debian9/install.amd/
rm initrd.gz
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian9.13/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
wget --no-check-certificate https://deb.debian.org/debian/dists/Debian9.13/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz

#Move preseeds
cp $PATH/needed-files/debian9/preseed.cfg /tftpboot/kickstart/debian9
cp $PATH/needed-files/debian10/preseed.cfg /tftpboot/kickstart/debian10
cp $PATH/needed-files/debian11/preseed.cfg /tftpboot/kickstart/debian11
cp $PATH/needed-files/centos7/ks.cfg /tftpboot/kickstart/centos7
cp $PATH/needed-files/freepbx/ks.cfg /tftpboot/kickstart/freepbx

#Create links
cd /var/www/html
ln -s /tftpboot/* /var/www/html
rm index.html

cd /tftpboot/BIOS/pxelinux.cfg/
ln -s ../../pxelinux.cfg/default .
cd /tftpboot/UEFI/pxelinux.cfg/
ln -s ../../pxelinux.cfg/default .

sed -i '1s/^/#Make sure to change the IPs to the IP of your system.\n/' /etc/dhcp/dhcpd.conf
nano /etc/dhcp/dhcpd.conf
sed -i '1s/^/#Make sure to change the IPs to the IP of your system.\n/' /tftpboot/pxelinux.cfg/default
nano /tftpboot/pxelinux.cfg/default

#Restart needed services
if [ "$(ls /etc | grep debian_version)" = "debian_version" ]; then
	systemctl restart tftp-hpa.service
	systemctl enable tftp-hpa
	systemctl restart apache*
	systemctl enable apache*

elif [ $(ls /etc | grep redhat-release) = "redhat-release" ]; then
	systemctl enable tftp-server
	systemctl start tftp-server
	systemctl enable dhcpd
	systemctl start dhcpd
else
	exit 1
fi

#Info
echo "Info: Kickstart files are disabled by default. Add users and hashed passwords to /tftpboot/kickstart files."
