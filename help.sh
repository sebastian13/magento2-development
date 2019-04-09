#!/bin/bash
DATE=`date +%Y%m%d`
ENV=".env"

echo
echo "---"
echo "--- Magento2 Create Development Script"
echo "--- https://github.com/sebastian13/magento2-development"
echo "---"
echo

usage() { echo "[USAGE] $0 [deploy|flush|fqdn|setup]" 1>&2; }

fqdn() {
	# Set Magento Domains

	if [ -z ${FQDN} ]
	then
		echo "[ERROR] FQDN is not defined in ${ENV}."
		exit 1
	fi

	# Starting required services
	docker-compose up -d fpm mysql

	echo "Putting ${FQDN} into the database"
	docker-compose exec fpm php bin/magento config:set web/unsecure/base_url http://${FQDN}/
	docker-compose exec fpm php bin/magento config:set web/secure/base_url https://${FQDN}/
	docker-compose exec fpm php bin/magento config:set web/cookie/cookie_domain ${FQDN}
	echo

	echo "Magento was set to the following domains"
	docker-compose exec fpm php bin/magento config:show web
	echo
}

flush() {
	echo "Flush Caches"
	docker-compose exec fpm php bin/magento cache:flush
	docker-compose exec redis redis-cli FLUSHALL
	echo
}

compile() {
	docker-compose exec fpm php bin/magento setup:di:compile
}

deploy() {
	echo "Removing and Regenerating Static Files"
	docker-compose exec fpm find pub/static -depth -name .htaccess -prune
	docker-compose exec fpm rm -rf var/cache/ var/composer_home var/generation/ var/page_cache/ var/view_preprocessed/ 
	docker-compose exec fpm php bin/magento setup:static-content:deploy de_AT en_US de_DE
}

setup() {
	echo "Running Setup"
	docker-compose exec fpm php bin/magento setup:upgrade
	docker-compose exec fpm php bin/magento setup:di:compile
	deploy
}

permissions() {
	docker-compose exec fpm chown -R www-data:www-data .
}

success() {
	echo "Done."
	exit 0
}

failed() {
	echo
	exit 1
}

if [ -z "$1" ]
then
	echo "[ERROR] No argument passed."
	usage
	failed
fi

# Read Environment File
if [ -f ${ENV} ]
then
	set -a
	source ${ENV}
	set +a
else
	echo "[ERROR] Could not find environment file."
	failed
fi

if [[ $1 = "fqdn" ]]
then
	echo "Replacing FQDN"
	fqdn
	flush
	deploy
	success
fi

if [[ $1 = "deploy" ]]
then
	echo "Starting deploy"
	flush
	deploy
	permissions
	success
fi

if [[ $1 = "flush" ]]
then
	echo "Flushing Caches"
	flush
	success
fi

if [[ $1 = "setup" ]]
then
	echo "Running Setup"
	flush
	setup
	deploy
	permissions
	success
fi

echo "[ERROR] Somethings wrong. Did you use a valid command?"
failed