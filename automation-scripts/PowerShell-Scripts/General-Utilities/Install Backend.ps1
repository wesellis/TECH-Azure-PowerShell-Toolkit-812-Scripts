<#
.SYNOPSIS
    Install Backend

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$mysqlpassword = $args[0]
$mySqlUser = $args[1]
$mySqlPasswordForUser=$args[2]
New-Item -ErrorAction Stop c:\Temp -type directory
echo "Downloading mysql"
$source = " http://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-5.7.11.0.msi"
$destination = "C:\Temp\mysql.msi";
$client = new-object -ErrorAction Stop System.Net.WebClient ;
$cookie = " oraclelicense=accept-securebackup-cookie"
$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
$client.DownloadFile($source,$destination)
Start-Process -Wait -FilePath msiexec -ArgumentList " /i c:\Temp\mysql.msi /quiet"
cd "C:\Program Files (x86)\MySQL\MySQL Installer for Windows"
cmd.exe /c 'MySQLInstallerConsole.exe community install server;5.7.11;x86:*:port=3306;rootpasswd=$mysqlpassword;servicename=MySQL -silent'
echo " add inbound rule"
cmd.exe /c " netsh advfirewall firewall add rule name="Allow mysql" dir=in action=allow edge=yes remoteip=any protocol=TCP localport=80,8080,3306"
cd  "C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin"
cmd.exe /c mysql -u root -p$mysqlpassword -e " grant all privileges on *.* to root@'localhost'" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " create database idp_db" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " use idp_db; create table StorageRecords(context varchar(255) NOT NULL,id varchar(255) NOT NULL,expires bigint(20) DEFAULT NULL,value longtext NOT NULL,version bigint(20) NOT NULL,PRIMARY KEY(context,id))" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " create user $mySqlUser@'localhost' identified by '$mySqlPasswordForUser'" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " grant all privileges on *.* to $mySqlUser@'localhost'" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " create user $mySqlUser@'%' identified by '$mySqlPasswordForUser'" ;
cmd.exe /c mysql -u root -p$mysqlpassword -e " grant all privileges on *.* to $mySqlUser@'%'" ;
net stop mysql
net start mysql

