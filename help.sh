#!/bin/bash
DATE=`date +%Y%m%d`
ENV=".env"

echo
echo "---"
echo "--- Magento2 Helper Script"
echo "--- https://github.com/sebastian13/magento2-development"
echo "---"
echo

usage() { echo "[USAGE] $0 [deploy|dev|flush|production|upgrade]" 1>&2; }

up() {
	echo "Start required services"
	docker-compose up -d
	sleep 1m
}

cache-enable() {
	echo "Enable Caches"
	docker-compose exec fpm php bin/magento cache:enable
	docker-compose exec redis redis-cli FLUSHALL
	echo
}

fqdn-dev() {
	# Set Magento Domains

	if [ -z ${FQDN_DEV} ]
	then
		echo "[ERROR] FQDN_DEV is not defined in ${ENV}."
		exit 1
	fi

	echo "Putting ${FQDN_DEV} into the database"
	docker-compose exec fpm php bin/magento config:set web/unsecure/base_url http://${FQDN_DEV}/
	docker-compose exec fpm php bin/magento config:set web/secure/base_url https://${FQDN_DEV}/
	docker-compose exec fpm php bin/magento config:set web/cookie/cookie_domain ${FQDN_DEV}
	echo

	echo "Magento was set to the following domains"
	docker-compose exec fpm php bin/magento config:show web
	echo
}

fqdn-prod() {
	# Set Magento Domains

	if [ -z ${FQDN} ]
	then
		echo "[ERROR] FQDN is not defined in ${ENV}."
		exit 1
	fi

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

setup-upgrade() {
	echo "Running Setup-Upgrade"
	docker-compose exec fpm php bin/magento setup:upgrade
	docker-compose exec fpm php bin/magento cache:flush
	docker-compose exec fpm php bin/magento cache:clean
}

stripe-dev() {
	echo "Setting Stripe to Testing Mode"
	docker-compose exec mysql /usr/bin/mysql -u root --password=${MYSQL_ROOT_PASSWORD} -e "UPDATE core_config_data SET value = 'test' WHERE path = 'payment/cryozonic_stripe/stripe_mode'" -D ${MYSQL_DATABASE}
}

stripe-prod() {
	echo "Setting Stripe to Production Mode"
	docker-compose exec mysql /usr/bin/mysql -u root --password=${MYSQL_ROOT_PASSWORD} -e "UPDATE core_config_data SET value = 'live' WHERE path = 'payment/cryozonic_stripe/stripe_mode'" -D ${MYSQL_DATABASE}
}

paypal-dev() {
	echo "Setting Paypal to Sanbox Mode"
	docker-compose exec mysql /usr/bin/mysql -u root --password=${MYSQL_ROOT_PASSWORD} -e "UPDATE core_config_data SET value = 1 WHERE path = 'paypal/wpp/sandbox_flag'" -D ${MYSQL_DATABASE}
}

paypal-prod() {
	echo "Setting Paypal to Production Mode"
	docker-compose exec mysql /usr/bin/mysql -u root --password=${MYSQL_ROOT_PASSWORD} -e "UPDATE core_config_data SET value = 0 WHERE path = 'paypal/wpp/sandbox_flag'" -D ${MYSQL_DATABASE}
}

permissions() {
	docker-compose exec fpm chown -R www-data:www-data .
}

permissions-dev() {
	echo "Make Magento2 directories writable for development. This can take a few minutes ..."
	docker-compose exec -u root fpm bash -c "rm -rf generated/metadata/* generated/code/*"
	docker-compose exec fpm php bin/magento deploy:mode:set developer
	docker-compose exec -u root fpm bash -c "find . ! -user www-data -print0 | xargs -0 --no-run-if-empty chown www-data:www-data"
	docker-compose exec -u root fpm bash -c "find var generated vendor pub/static pub/media app/etc -type d ! -perm 775 -print0 | xargs -0 --no-run-if-empty chmod 775"
	docker-compose exec -u root fpm bash -v "find var generated vendor pub/static pub/media app/etc -type f ! -perm 664 -print0 | xargs -0 --no-run-if-empty chmod 664"
	echo
}

permissions-prod() {
	echo "Settings File systems access permissions for production"
	docker-compose exec fpm php bin/magento deploy:mode:set production
	docker-compose exec fpm bash -c "find var generated vendor pub/static pub/media app/etc -type d ! -perm 755 -print0 | xargs -0 --no-run-if-empty chmod 755"
	docker-compose exec fpm bash -c "find var generated vendor pub/static pub/media app/etc -type f ! -perm 644 -print0 | xargs -0 --no-run-if-empty chmod 644"
	docker-compose exec fpm chmod o-rwx app/etc/env.php
	echo
}

reindex() {
	echo "Running Reindex"
	docker-compose exec fpm php bin/magento index:reindex
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

if [[ $1 = "deploy" ]]
then
	echo "Starting deploy"
	flush
	deploy
	permissions
	success
fi

if [[ $1 = "dev" ]]
then
	echo "Changing to development"
	up
	permissions-dev
	fqdn-dev
	flush
	deploy
	paypal-dev
	stripe-dev
	reindex
	compile
	deploy
	success
fi

if [[ $1 = "flush" ]]
then
	echo "Flushing Caches"
	flush
	success
fi

if [[ $1 = "production" ]]
then
	echo "Changing to production"
	up
	fqdn-prod
	paypal-prod
	stripe-prod
	flush
	reindex
	compile
	deploy
	mode-prod
	cache-enable
	success
fi

if [[ $1 = "upgrade" ]]
then
	echo "Running Upgrade"
	flush
	setup-upgrade
	compile
	reindex
	deploy
	permissions
	success
fi

echo "[ERROR] Somethings wrong. Did you use a valid command?"
failed