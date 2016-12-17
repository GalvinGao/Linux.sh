#!/bin/bash

# Function: Backup website files and MySQL database
# Author: licess
# Website: http://www.lnmp.org/ and Galvin Gao edited.

# IMPORTANT!!! Please Setting the following Values! #

Backup_Files_Will_Be_Storage_At="/home/backup/"
MySQL_Dump="/usr/local/mysql/bin/mysqldump"

# Set Directory you want to backup #
Backup_Dir=("/path/to/backup/file")

# Set MySQL Database you want to backup #
Backup_Database=("backupDatabase")

# Set MySQL Username and Password #
MYSQL_Username='yourMysqlUsernameHere'
MYSQL_Password='yourMysqlPasswordHere'

# FTP Backup Toggle #
Enable_FTP=1
# 0: Enable; 1: Disable #

# Set FTP Login Information #
FTP_Host=''
FTP_Username=''
FTP_Password=''
FTP_Dir=""

####################################
######## Values Setting END! #######
# Do not edit enything under here! #
####################################

TodayWWWBackup=www-*-$(date +"%Y%m%d").tar.gz
TodayDBBackup=db-*-$(date +"%Y%m%d").sql
OldWWWBackup=www-*-$(date -d -3day +"%Y%m%d").tar.gz
OldDBBackup=db-*-$(date -d -3day +"%Y%m%d").sql

Backup_Dir()
{
    Backup_Path=$1
    Dir_Name=`echo ${Backup_Path##*/}`
    Pre_Dir=`echo ${Backup_Path}|sed 's/'${Dir_Name}'//g'`
    tar zcf ${Backup_Home}www-${Dir_Name}-$(date +"%Y%m%d").tar.gz -C ${Pre_Dir} ${Dir_Name}
}
Backup_Sql()
{
    ${MySQL_Dump} -u$MYSQL_Username -p$MYSQL_Password $1 > ${Backup_Files_Will_Be_Storage_At}db-$1-$(date +"%Y%m%d").sql
}

if [ ! -f ${MySQL_Dump} ]; then  
    echo "backup: mysqldump command not found. Please check your setting."
    exit 1
fi

if [ ! -d ${Backup_Files_Will_Be_Storage_At} ]; then  
    mkdir -p ${Backup_Files_Will_Be_Storage_At}
fi

type lftp >/dev/null 2>&1 || { echo >&2 "backup: lftp command not found. To install lftp: CentOS: yum install lftp ; Debian/Ubuntu: apt-get install lftp."; }

echo "Backup files..."
for dd in ${Backup_Dir[@]};do
    Backup_Dir ${dd}
done

echo "Backup Databases..."
for db in ${Backup_Database[@]};do
    Backup_Sql ${db}
done

echo "Delete old backup files..."
rm -f ${Backup_Home}${OldWWWBackup}
rm -f ${Backup_Home}${OldDBBackup}

if [ ${Enable_FTP} = 0 ]; then
    echo "Uploading backup files to ftp..."
    cd ${Backup_Files_Will_Be_Storage_At}
    lftp ${FTP_Host} -u ${FTP_Username},${FTP_Password} << EOF
cd ${FTP_Dir}
mrm ${OldWWWBackup}
mrm ${OldDBBackup}
mput ${TodayWWWBackup}
mput ${TodayDBBackup}
bye
EOF

echo "Backup complete."
fi
