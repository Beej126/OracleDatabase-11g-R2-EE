#!/bin/bash
v_oracle_website_user=peng.alan@gmail.com
v_oracle_website_password=Docker88

v_cookie=/tmp/$$_cookie
v_download_oracledb11g=http://download.oracle.com/otn/linux/oracle11g/R2/linux.x64_11gR2_database_1of2.zip

# Download Weblogic1036
v_Site2pstoreToken=`curl -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0" -L $v_download_oracledb11g | grep site2pstoretoken | awk -Fsite2pstoretoken {'print $2'}|awk -F\= {'print  $2'}|awk -F\" {'print $2'}`

curl -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.6.0"  \
-d 'ssousername='$v_oracle_website_user'&password='$v_oracle_website_password'&site2pstoretoken='$v_Site2pstoreToken \
-o /dev/null \
https://login.oracle.com/sso/auth -c $v_cookie

echo '.oracle.com	TRUE	/	FALSE	0	oraclelicense	accept-dbindex-cookie' >> $v_cookie

curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.6.0" \
-b $v_cookie \
-OL $v_download_oracledb11g
mv linux.x64_11gR2_database_1of2.zip /install/disk1.zip
