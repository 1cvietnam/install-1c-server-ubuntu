# Download 1C Fresh sources
DISTRIB='fresh-install-64-8.3.11.3034'

source util.sh

message "install Curl"

sudo apt-get  --yes --force-yes install curl

message "download sources"

sudo curl -O http://ftp.1c.com.vn/$DISTRIB.tar.gz
sudo tar -xzf $DISTRIB.tar.gz

message "copy sources to /fresh-install"

sudo mkdir /fresh-install
sudo cp -a $DISTRIB/* /fresh-install/

message "delete sources"

sudo rm -fr $DISTRIB
sudo rm $DISTRIB.tar.gz

message "ALL DONE"
