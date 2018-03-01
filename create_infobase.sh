# Install 1C Fresh Ubuntu (server and infobases)

# Accept 2 parameters:
# -a: fresh infobase name
# -p: solution infobase name

#Suppress interactive questions
export DEBIAN_FRONTEND=noninteractive

#Exit on error
set -e

if [[ $# -eq 1 ]] ; then
  base_name=$1
else
  echo 'Please provide infobase name: create_infobase.sh your_infobase_name'
  exit 1
fi

source util.sh

# SET UP base_name INFOBASE
message "set up Server"

sudo service srv1cv83 restart

# create variable for server and console agents
mras='/opt/1C/v8.3/x86_64/ras'
mrac='/opt/1C/v8.3/x86_64/rac'

message "set up Infobase"

$mras cluster --daemon
# get cluster id
cluster=$(echo $($mrac cluster list) | cut -d':' -f 2 | cut -d' ' -f 2)
echo "cluster:" $cluster
# get server name
server=$(echo $($mrac cluster list) | cut -d':' -f 3 | cut -d' ' -f 2)
echo "server:" $server
# create infobase for solution
$mrac infobase create --create-database --name=$base_name --dbms=PostgreSQL --db-server=$server --db-name=$base_name --locale=en_US --db-user=postgres --db-pwd=12345Qwerty --descr=$base_name --license-distribution=allow --cluster=$cluster >> infobase
# retrieving base_name infobase id
infobase2=$(cat infobase | cut -d':' -f 2 | cut -d' ' -f 2)
echo $base_name ":" $infobase2
rm infobase
# getting sumary 
$mrac infobase summary list --cluster=$cluster
$mrac infobase info --infobase=$infobase1 --cluster=$cluster
$mrac infobase info --infobase=$infobase2 --cluster=$cluster

message "publish Solution Infobase"

sudo chmod o+w /etc/apache2/my_bases
sudo cp conf/etc/apache2/my_bases/app.conf "/etc/apache2/my_bases/$base_name.conf"
sudo sed -i "s/<--ibname-->/$base_name/g" "/etc/apache2/my_bases/base_name.conf"
sudo chmod o-w /etc/apache2/my_bases

sudo mkdir -p /var/www/my_bases/$base_name/

sudo chmod o+w "/var/www/my_bases/$base_name"
sudo cp conf/var/www/my_bases/default.vrd "/var/www/my_bases/$base_name/default.vrd"
sudo sed -i "s/<--ibname-->/$base_name/g" "/var/www/my_bases/$base_name/default.vrd"
sudo sed -i "s/<--server_name-->/$server/g" "/var/www/my_bases/$base_name/default.vrd"
sudo chmod o-w "/var/www/1cfresh/a/$base_name"

message "Infobases are published"

sudo ufw allow 234
sudo ufw allow 22
sudo ufw allow 1540
sudo ufw allow 1541
sudo ufw allow 1560
sudo ufw enable
sudo ufw status

message "ALL DONE"
