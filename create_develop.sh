#!/bin/bash
DATE=`date +%Y%m%d`

#LIVE_DIRECTORY=$1
#DEV_DIRECTORY=$2/${DATE}develop

#if [ ! "$1" ] || [ ! "$2" ]
#then
#    echo "Please specify two paths. The path to your live directory, and the path where you want the develop directory to be!"
#    exit 1
#fi
#
#if [ ! -d "$LIVE_DIRECTORY" ]; then
#    echo "$LIVE_DIRECTORY"
#    echo "Seems that your Live Directory does not exist!"
#    exit 1
#fi

#DB_USER=root

# Define usable parameters
while getopts ":u:d:p:f:" opt; do
  case $opt in
    d) DEV_DOMAIN=${OPTARG}
	echo
	echo "Your Settings"
	echo "-------------"
	echo "Domain		| $OPTARG" >&2
	;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  
  esac
done

# Define arguments [source] and [destination]
shift $(($OPTIND-1))
LIVE_DIRECTORY=$1
DEV_DIRECTORY=$2/${DATE}develop

length=${#LIVE_DIRECTORY}
last_char=${LIVE_DIRECTORY:length-1:1}
[[ $last_char != "/" ]] && LIVE_DIRECTORY="$LIVE_DIRECTORY/"; :

echo "Live directory	| $LIVE_DIRECTORY"
echo "Dev. directory	| $DEV_DIRECTORY"
echo

# Check if [source] and [destination] were provided
if [ ! "$1" ] || [ ! "$2" ]
then
    echo "Please specify two paths. The path to your live directory, and the path where you want the develop directory to be!"
    exit 1
fi

# Check existence of Live Directory
if [ ! -d "$LIVE_DIRECTORY" ]; then
    echo "$LIVE_DIRECTORY"
    echo "Seems that your Live Directory does not exist!"
    exit 1
fi

# Check if Domain-Name was provided
if [ ! "$DEV_DOMAIN" ]
then
    echo "Please specify a domain using the -d option!"
    exit 1
fi

# Check existence of [destination]
if [ -d "$DEV_DIRECTORY" ]; then
    echo "The directory $DEV_DIRECTORY already exists. Please remove it, if you want to start from scratch."
    
    read -p "Do you want to proceed anyways? Press [Y] to overwrite the directory $DEV_DIRECTORY and remove the running containers! [yN] " -n 1 -r
    echo #  move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
	echo "Ok. I will continue!"
	docker-compose -f $DEV_DIRECTORY/docker-compose.yml stop
	docker-compose -f $DEV_DIRECTORY/docker-compose.yml rm -f
	echo
    else
        echo "Ok. Won't do anything. Good bye!"    
        exit 1
    fi
fi

# Copy files fron [source] to [destination]
echo "Your Live Directories will be copied to $DEV_DIRECTORY now!"
rsync --info=progress2 -a --delete $LIVE_DIRECTORY $DEV_DIRECTORY

# Pull & Start Development Containers
docker-compose -f $DEV_DIRECTORY/docker-compose.yml pull
docker-compose -f $DEV_DIRECTORY/docker-compose.yml up -d

APACHE=${DEV_DIRECTORY}_apache_1
REDIS=${DEV_DIRECTORY}_cache_1

# Set file + directory permissions
echo "Make Magento2 directories writable for development. This will take a few minutes ..."
docker exec $APACHE find app/code lib var pub/static pub/media vendor app/etc \( -type d -or -type f \) -exec chmod g+w {} \;
docker exec $APACHE chmod o+rwx app/etc/env.php
echo

# Change Magento Domains
echo "Putting your url into the database now."
docker exec $APACHE php bin/magento config:set web/unsecure/base_url http://$DEV_DOMAIN/
docker exec $APACHE php bin/magento config:set web/secure/base_url https://$DEV_DOMAIN/
docker exec $APACHE php bin/magento config:set web/cookie/cookie_domain $DEV_DOMAIN
echo

echo "The Magento database was configured to the following domains:"
docker exec $APACHE php bin/magento config:show web
echo

echo "Delete Caches"
docker exec $APACHE php bin/magento cache:flush
docker exec -it $REDIS redis-cli FLUSHALL
echo

#docker exec -it ${DEV_DIRECTORY_NAME}_db_1 /usr/bin/mysql --defaults-file=/root/.my.cnf -D magento2
#    UPDATE core_config_data \
#        SET core_config_data.value='https://dev.libuni.eu/' \
#        WHERE core_config_data.path='web/unsecure/base_url' \
#            OR core_config_data.path='web/secure/base_url';

#    UPDATE core_config_data
#        SET core_config_data.value='dev.libuni.eu'
#        WHERE core_config_data.path='web/cookie/cookie_domain';

#    quit
#exit

# Update Upstream in Nginx-Proxy
#sed -i "/set \$upstream_magento/c\\\tset \$upstream_magento ${DEV_DIRECTORY_NAME}_apache_1; # updated by create_develop.sh" \
#    00-nginx-proxy/conf.d/dev.libuni.eu.conf

# Restart Nginx-Proxy
#docker exec 00-nginx-proxy service nginx reload

#docker exec --user www-data $APACHE php bin/magento index:reindex
#docker exec --user www-data $APACHE php bin/magento setup:di:compile
#docker exec --user www-data $APACHE php bin/magento setup:static-content:deploy de_AT en_US de_DE