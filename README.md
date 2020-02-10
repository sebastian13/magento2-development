# Magento2 helper

This script helps running frequently used Magento 2 commands. It's build to be used with an environment similar to [fballiano's](https://github.com/fballiano/docker-magento2).

### Requirements
* docker-compose
* `docker-compose.yml` file
* `.env` file

### Usage

1. Clone

	```bash
	mkdir ~/magento2-helper
	git clone https://github.com/sebastian13/magento2-helper.git ~/magento2-helper
	chmod +x ~/magento2-helper/*.sh
	```

2. Provide `.env` file

	```bash
	FQDN=example.com
	FQDN_DEV=test.example.com
	MYSQL_DATABASE=
	MYSQL_ROOT_PASSWORD=
	```

3. Run the script

	```bash
	cd /docker/example
	~/magento2-helper/help.sh [deploy|flush|fqdn|setup]
	```

	#### Commands

	| Command  | Description  |
	|----------| :--------------------------------------------------|
	| `deploy` | - Removes static files<br/> - Runs setup:static-content |
	| `dev` | - Creates a development instance |
	| `flush` | - Flushes magento/varnish cache<br/> - Flushes redis cache |
	| `production` | - Sets production FQDN<br/> - Sets paypal to production<br/> - Sets stripe to production<br/> - mode production<br/> - enables cache |
	| `upgrade` | - Flushes the cache<br/> - Runs setup:upgrade<br> - Runs setup:di:compile<br> - Removes and regenerate static files |
	
### Example: Test-Setup

1. Dupliate directory

	```
	rsync --info=progress2 -a <LIVE_DIRECTORY>/ <DEV_DIRECTORY>
	```
	
2. Prepare directories for changes

