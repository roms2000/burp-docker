# Burp docker container

This repository contains files to build burp container which includes burp-ui, burp reports, maintenance task and email sending capability.
It is based on the repository made by Ronivay : https://github.com/ronivay/burp-docker

Burp is an open source backup and restore software for Unix and Windows clients.
https://burp.grke.org/

Burp-UI is a great project which applies a graphical user interface to interact with the server, edit settings and manage clients.
https://github.com/ziirish/burp-ui

Burp reports : helpful reports for burp backup and restore.
https://github.com/pablodav/burp_server_reports

The conatiner contains maintenace tasks :
 - Burp bedup (deduplication if need)
 - Burp delete  (option manual_delete)
 - Burp Reports (report outdated backup/client by mail)

## Installation

Choice :

 - Install from GIT and build the docker image
or 
 - Install the docker image

### Installation from GIT

- Clone this repository
```
git clone https://github.com/roms2000/burp-docker
```

- build docker container manually

```
cd container
docker build -t burp-server .
```

### Installation from Docker

-  Pull from dockerhub

```
docker pull roms2000/burp-docker
```

## Launch the container

Choice :
-  with `docker run`
or 
- with `docker-compose`

### Run the docker container 

- run it with defaults values for testing purposes. 

```
docker run -itd -p 5000:5000 -p 4971:4971 -p 4972:4972 burp-docker
```

Burp-UI is now accessible at `http://your-server-ip:5000`. Default username and password admin/admin

You can leave ports 4971 and 4972 out if you just want to try the UI.

Burp-UI is now accessible at `http://your-server-ip:5000`. Password for admin user is the one you defined in `WEBUI_ADMIN_PASSWORD` variable.

### Running with docker-compose

- Other than testing, suggested method is to use the provided docker-compose file. Edit the variables to your preference and start up the environment

```
docker-compose up -d
```


# Variables

`MACHINENAME`

The machine/container name.

`NOTIFY_SUCCESS` 

Boolean value true/false for receiving notifications on successfull backups via email. 

`NOTIFY_FAILURE`

Boolean value true/false for receiving notification on failed backups via email.

`FROM_EMAIL`

Email address of the sender.

`NOTIFY_EMAIL`

Email address where notifications are sent to.

`SMTP_RELAY`

SMTP relay server address. Optional and postfix inside container will send emails directly if not defined.

`SMTP_PORT`

Optional SMTP relay port number when SMTP_RELAY is set. Defaults to 25 if not set.

`SMTP_AUTH`

Optional username/password when SMTP_RELAY is set.

Use format username:password

`SMTP_TLS`

Boolean value yes/no for TLS when SMTP_RELAY is set. Defaults to no if not set.

`RESTOREPATH`

Path where restored files via burp-ui are stored. Slashes need to be escaped in this, example: `\/tmp\/bui`

`BUI_USER`

Username which burp-ui uses to interact with the server.

`BUI_USER_PASSWORD`

BUI_USER password for burp-ui to interact with the server.

`WEBUI_ADMIN_PASSWORD`

burp-ui admin user password. 

`ENABLE_BURP_DELETE`

Enable the cron task to delete postpone old backup. Default to true. 

`ENABLE_BURP_BEDUP`

Enable the cron task to deduplicate files. Default to false. 

`ENABLE_BURP_REPORTS`

Enable the cron task to get burp reports. Default to true. 



# Volumes

There are few important mountpoints you should note if preserving data is important (usually it is unless you're not just testing this).

`/etc/burp` - configuration path

`/var/spool/burp` - path for backup store

`/tmp/bui` - default path for restored files when done from burp-ui

`/var/log/burp-ui` - burp-ui access/error logs are not redirected to container stdout. mount a volume from host if you want to see/preserve these logs

You should mount a path from host machine to these for best outcome.

