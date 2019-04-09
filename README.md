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

1. Run

 ```bash
cd /docker/example
~/magento2-helper/help.sh [deploy|flush|fqdn|setup]
```

### Commands

| Command  | Description  |
|----------| :--------------------------------------------------|
| `deploy` | Removes static files and runs setup:static-content |
| `flush`  | Flushes magento and redis cache                    |
| `fqdn`   | Replace the Domain Name                            |
| `setup`  | Runs setup:upgrade and setup:di:compile            |

### .env

The .env file should contain the following variables

```bash
FQDN=example.com
MYSQL_DATABASE=
MYSQL_ROOT_PASSWORD=
```