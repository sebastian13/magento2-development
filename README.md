# Create Magento2 development containers

This script takes your existing Magento2 docker containers and creates a development environment for you. It's build to be used with an environment similar to [fballiano's](https://github.com/fballiano/docker-magento2).

### Requirements
* docker-compose installed
* A **docker-compose.yml** file in your live directory

### Parameters

Parameter | Expected Syntax | Description | Necessary |
:-------: | --------------- | :---------- | --- |        
-d        | dev.examle.com  | Your Development Domain            | required
-p        |                 | Sets PayPal-Express to Testing     | optional
-s        |                 | Sets Cryzionic Stripe to Testing   | optional
-n | | Creates a nginx conf file which you can use in your nginx-proxy | optional
-h | | Displays instructions |

<!--
-w        | apache          | The name of your webserver service | required
-->

### How to use

```bash
git clone ... ~/m2-dev
chmod +x ~/m2-dev/create_develop.sh
~/m2-dev/create_develop.sh -d example.com -p -s -n [/path/to/your/running/instance] [/path/to/copy/directory/to]
```

### What it does
1. **Copy the directory** provided to the location provided using rsync.
2. docker-compose pull: **Downloads containres** specified in docker-compose.yml
3. docker-compose up -d: **Starts containers**
4. **Updates** file and folder **permissions** according to Magento's specifications for a development environment
5. Updates Magento's **URL**
6. Delete and **disables Cache**
1. *Optional: Sets PayPal to Testing*
1. *Optional: Sets Stripe to Testing*
1. *Optional: Creates nginx.conf file*
1. Runs Magento reindex, setup:di:compile and static-content:deploy

### What it does not do (yet)
1. Enables the nginx.conf file. You need to manually move it to your nginx-proxy