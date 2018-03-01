# Install 1C Fresh Ubuntu (environment)

# Declare the function that echoes messages
# The first parameter is the message

source util.sh

# Check if $1 service is up and running
# If servise is down the script will stop
function check_service_stat() {
	service $1 status | grep "Active: active" | grep -v grep > /dev/null
	if [ $? != 0 ]; then
		echo "ERROR: $1 service is NOT running!!!"
		exit 1;
	else
		echo "$1 service is up and running"
 	fi;	
}

#Suppress interactive questions
export DEBIAN_FRONTEND=noninteractive

#Exit on error
set -e

# INSTALL TOOLS
message "Set up the environment"

message "Update packages"
#cd
sudo apt-get update -y

# INSTALL APACHE, CREATE FOLDERS
message "Install Midnight Commander"

sudo apt-get --yes --force-yes install mc

message "Install support component (run one by one)"

sudo apt-get --yes --force-yes install gdebi-core
sudo apt-get --yes --force-yes install ntp ntpdate

message "Install Apache and check status"

sudo apt-get --yes --force-yes install apache2
check_service_stat "apache2"

message "Create subfolders and empty configs for futher infobase publications"

sudo mkdir -p /etc/apache2/my_bases 
sudo touch /etc/apache2/my_bases/empty.conf

message "Set up default ports and ports that will be used for infobases"

sudo chmod o+w /etc/apache2/ports.conf
sudo cp conf/etc/apache2/ports.conf /etc/apache2/
sudo chmod o-w /etc/apache2/ports.conf

message "Restart Apache and check status"

sudo service apache2 restart
check_service_stat "apache2"

# INSTALL POSTGRESQL
message "Set locale and environment variable"

sudo locale-gen en_US ru_RU ru_RU.UTF-8
export LANG="ru_RU.UTF-8"

message "Install Postgres (run one by one)"

yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/libicu48_4.8.1.1-3_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/libossp-uuid16_1.6.2-1.3ubuntu1_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/libpq5_9.3.4-1.1C_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/postgresql-client-common_154.1.1C_all.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/postgresql-client-9.3_9.3.4-1.1C_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/postgresql-common_154.1.1C_all.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/postgresql-9.3_9.3.4-1.1C_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/postgresql-9.3.4_1.1C_amd64_deb/postgresql-contrib-9.3_9.3.4-1.1C_amd64.deb

message "Create folder for PostgreSQL databse"

sudo mkdir -p /1c/db

message "Give 'postgres' user access to folder /1c/db"

sudo chown postgres:postgres /1c/db

message "Initialize PostreSQL DB"

if sudo [ ! -f /1c/db/pg_hba.conf ]; then
	message "Initialize PostreSQL DB"
	sudo su - postgres -c "/usr/lib/postgresql/9.3/bin/initdb -D /1c/db --locale=ru_RU.UTF-8"
else
	message "PostgreSQL DB was NOT initialized because /1c/db is NOT empty. Assuming the DB was initialized before"
fi

message "Replace one string with another in /etc/postgresql/9.3/main/pg_hba.conf"

sudo sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' /etc/postgresql/9.3/main/pg_hba.conf

message "restart postgresql service"

sudo service postgresql restart

message "Set up a password for postgres user"

sudo psql -U postgres -c "alter user postgres with password '12345Qwerty';" 

message "comment all lines and replace one line with these three lines"

sudo sed -i 's/^\([^#]\)/# \1/g' /etc/postgresql/9.3/main/pg_hba.conf
sudo sed -i 's/# local   all             postgres                                trust/local   all             postgres                                peer\nlocal   all             all                                     md5\nhost    all             postgres              127.0.0.1\/32      md5/' /etc/postgresql/9.3/main/pg_hba.conf

message "Restart postgresql service"

sudo service postgresql restart

# INSTALL 1C
message "Install 1C Server x64 (run one by one)"

yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-common_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-common-nls_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-server_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-server-nls_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-ws_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-ws-nls_amd64.deb

message "Give 'usr1cv8' user access to folder /opt/1C"

sudo chown -R usr1cv8 /opt/1C

message "Start 1C Server and check status"

sudo service srv1cv83 start
check_service_stat "srv1cv83"

message "Create conf file for tech journal"

sudo mkdir -p /opt/1C/v8.3/x86_64/conf
sudo chmod o+w /opt/1C/v8.3/x86_64/conf
sudo cp conf/opt/1C/v8.3/x86_64/conf/logcfg.xml /opt/1C/v8.3/x86_64/conf/
sudo chmod o-w /opt/1C/v8.3/x86_64/conf/logcfg.xml

message "Create folders for tech journal"

sudo mkdir -p /var/log/1c/logs/excp 
sudo mkdir -p /var/log/1c/logs/vrs 
sudo mkdir -p /var/log/1c/dumps

message "Create 'grp1clogs' user group for users (apache and 1c server)"

sudo getent group grp1clogs 2>&1 > /dev/null || sudo groupadd grp1clogs
sudo usermod -a -G grp1clogs www-data
sudo usermod -a -G grp1clogs usr1cv8

echo "Give user group 'grp1clogs' acces to tech log folders"

sudo chown -R usr1cv8:grp1clogs /var/log/1c 
sudo chmod g+rw /var/log/1c

echo "Users"

ps aux | grep /opt/1C/v8.3/x86_64/ | grep -v grep | cut -c 1-65 
ps aux | grep apache2 | grep -v grep | cut -c 1-65

message "Install imagemagick"

sudo apt-get -y install imagemagick
sudo find / -xdev -name "*libMagickWand*"

message "Create a link to libMagickWand.so"

if [ ! -e /usr/lib/libMagickWand.so ]; then
	sudo ln -s /usr/lib/x86_64-linux-gnu/libMagickWand-6.Q16.so.2.0.0 /usr/lib/libMagickWand.so
fi

message "Install ms fonts"

sudo apt-get -y install ttf-mscorefonts-installer
sudo fc-cache -fv
if [ ! -e /etc/fonts/conf.d/10-autohint.conf ]; then
	sudo ln -s /etc/fonts/conf.avail/10-autohint.conf /etc/fonts/conf.d/10-autohint.conf
fi

# HASP
#message "Install HASP"

#sudo apt-get -y install libc6:i386
#yes | sudo gdebi /fresh-install/hasp/haspd_7.40-eter10ubuntu_amd64.deb

#message "Start HASP and check status"

#sudo service haspd start
#check_service_stat "haspd"

# 1C WS
message "Add wsap24 library to apache"

sudo chmod o+w /etc/apache2/mods-enabled
sudo cp conf/etc/apache2/mods-enabled/wsap24.load /etc/apache2/mods-enabled/
sudo chmod o-w /etc/apache2/mods-enabled/wsap24.load

# 1C Debug
message "Enable debug"

sudo service srv1cv83 stop
sudo sed -i 's/#SRV1CV8_DEBUG=/SRV1CV8_DEBUG=1/' /etc/init.d/srv1cv83
sudo service srv1cv83 start
check_service_stat "srv1cv83"
sudo systemctl daemon-reload
message "Check ports listeners"

sudo netstat -peant | grep :15

# INSTALL 1C CLIENT
message "install 1C client"

yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-client_amd64.deb
delimiter
yes | sudo gdebi /fresh-install/deb-client-server-64/1c-enterprise83-client-nls_amd64.deb

message "ALL DONE"
