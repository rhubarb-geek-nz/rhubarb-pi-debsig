#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.sh 80 2021-12-03 11:48:59Z rhubarb-geek-nz $
#

APPNAME=rhubarb-pi-debsig

svnVer()
{
	while read A B C D
	do
		echo $C
	done << 'EOF'
$Id: package.sh 80 2021-12-03 11:48:59Z rhubarb-geek-nz $
EOF
}

cleanup()
{
	rm -rf control.tar.* control data data.tar.* debian-binary
}

cleanup

trap cleanup 0

USEHTTPS=true

dpkg -l debsig-verify

PKGVERS=$( dpkg -l debsig-verify | grep "ii " | grep debsig-verify | grep $(dpkg --print-architecture) | while read A B C D; do echo $C; break; done )

test -n "$PKGVERS"

PKGVERS=$( echo "$PKGVERS" | sed "y/./ /; y/+/ /; y/-/ /" )

echo PKGVERS=$PKGVERS

while read MAJVERS MINVERS
do
	if test "$MAJVERS" -eq 0
	then
		if test "$MINVERS" -lt 15
		then
			USEHTTPS=false
		fi
	fi
	break
done << EOF
$PKGVERS
EOF

echo USEHTTPS=$USEHTTPS

SVNVER=`svnVer`
VERSION="1.0.$SVNVER"
DPKGARCH=all
if $USEHTTPS
then
	HTTP_PROTO=https
	DEPENDS="debsig-verify (>= 0.15)"
else
	DEPENDS="debsig-verify (<< 0.15)"
	HTTP_PROTO=http
fi
KEYID=72DD1FFFFA779633FD430DC5006C5A2905B4D63C
KEYTHUMB=`echo $KEYID | tail -c 17`
KEYNAME=rhubarb-geek-nz
MAINTAINER="rhubarb-geek-nz@users.sourceforge.net"

mkdir control data

mkdir -p data/etc/debsig/policies/$KEYTHUMB data/usr/share/debsig/keyrings/$KEYTHUMB

gpg --list-keys "$KEYID" 

gpg --export "$KEYID" > data/usr/share/debsig/keyrings/$KEYTHUMB/$KEYNAME.gpg

cat > data/etc/debsig/policies/$KEYTHUMB/$KEYNAME.pol <<EOF
<?xml version="1.0"?>
<!DOCTYPE Policy SYSTEM "$HTTP_PROTO://www.debian.org/debsig/1.0/policy.dtd">
<Policy xmlns="$HTTP_PROTO://www.debian.org/debsig/1.0/">
  <Origin Name="$KEYNAME" id="$KEYTHUMB" Description="$MAINTAINER"/>
  <Selection>
     <Required Type="origin" File="$KEYNAME.gpg" id="$KEYTHUMB"/>
  </Selection>
  <Verification MinOptional="0">
     <Required Type="origin" File="$KEYNAME.gpg" id="$KEYTHUMB"/>
  </Verification>
</Policy>
EOF

cat data/etc/debsig/policies/$KEYTHUMB/$KEYNAME.pol

PACKAGE_NAME="$APPNAME"_"$VERSION"_"$DPKGARCH".deb

(
	cat <<EOF
Package: $APPNAME
Version: $VERSION
Architecture: $DPKGARCH
Maintainer: $MAINTAINER
Depends: $DEPENDS
Section: admin
Priority: extra
Description: debsig public key and policy
EOF
) > control/control

cat control/control

for d in control data
do
	(
		set -e
		cd $d
		if test -f control
		then
			tar --owner=0 --group=0 --create --gzip --file ../$d.tar.gz control
		else
			tar --owner=0 --group=0 --create --gzip --file ../$d.tar.gz etc/debsig/policies/$KEYTHUMB usr/share/debsig/keyrings/$KEYTHUMB
		fi
	)
done

rm -rf "$PACKAGE_NAME"

echo "2.0" >debian-binary

ar r "$PACKAGE_NAME" debian-binary control.tar.* data.tar.*

ar p "$PACKAGE_NAME" data.tar.* | tar tvfz -

debsigs --sign origin -k "$KEYID" "$PACKAGE_NAME"

ar t "$PACKAGE_NAME"
