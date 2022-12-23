#!/bin/bash

SSL_KEY_RANDOM_PASS=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
APPSECRET_RANDOM_PASS=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
BUI_USER=${BUI_USER:-bui}
BUI_USER_PASSWORD=${BUI_USER_PASSWORD:-password}
WEBUI_ADMIN_PASSWORD=${WEBUI_ADMIN_PASSWORD:-admin}
RESTOREPATH=${RESTOREPATH:-/tmp/bui}
NOTIFY_EMAIL=${NOTIFY_EMAIL:-youremail@example.com}
FROM_EMAIL=${FROM_EMAIL:-sender@example.com}
SMTP_PORT=${SMTP_PORT:-25}
MACHINENAME=${MACHINENAME:-burp-docker}

# configure postfix
postconf -e 'inet_protocols = ipv4'
postconf -e 'inet_interfaces = all'

if [[ ${SMTP_RELAY} ]] && [[ ! -z ${SMTP_RELAY} ]]; then
	postconf -e "relayhost = [${SMTP_RELAY}]:${SMTP_PORT}"
	if [[ ${SMTP_AUTH} ]] && [[ ! -z ${SMTP_AUTH} ]]; then
		postconf -e "smtp_sasl_auth_enable = yes"
		postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
		postconf -e "smtp_sasl_security_options = noanonymous"
                echo "[${SMTP_RELAY}]:${SMTP_PORT} ${SMTP_AUTH}" > /etc/postfix/sasl_passwd
                postmap /etc/postfix/sasl_passwd
	fi
	if [[ ${SMTP_TLS} == "yes" ]]; then
		postconf -e "smtp_use_tls = yes"
	fi
fi

# Copy burp config if they don't exist
if [[ -z $(ls -A /etc/burp) ]]; then
	cp -pr /etc/burp-src-conf/* /etc/burp/
fi

# Start with clean config files
if [ ! -e /etc/burp/burp-server.conf ] ; then 
	echo "# Burp server" > /etc/burp/burp-server.conf
	cat /etc/burp-src-conf/burp-server.conf | grep -v '#' | grep -v -E '^$' >> /etc/burp/burp-server.conf
	grep -E '^\s*listen_status' /etc/burp/burp-server.conf || echo 'listen_status = 127.0.0.1:4972' >> /etc/burp/burp-server.conf
	grep -E '^\s*max_status_children' /etc/burp/burp-server.conf || echo 'max_status_children = 15' >> /etc/burp/burp-server.conf
fi
if [ ! -e /etc/burp/burpui.cfg ] ; then 
	cp -p /etc/burp-src-conf/burpui.cfg /etc/burp/burpui.cfg
fi
if [ ! -e /etc/burp/burpui_gunicorn.py ] ; then 
	cp -p /etc/burp-src-conf/burpui_gunicorn.py /etc/burp/burpui_gunicorn.py
fi
if [ ! -e /etc/burp/burp-reports.conf ] ; then
	cp -p /etc/burp-src-conf/burp-reports.conf /etc/burp/burp-reports.conf
fi

# enable bui user to act as restore client
grep "restore_client = ${BUI_USER}" /etc/burp/burp-server.conf || echo "restore_client = ${BUI_USER}" >> /etc/burp/burp-server.conf

# performance enhancement
grep "monitor_browse_cache = 1" /etc/burp/burp-server.conf || echo "monitor_browse_cache = 1" >> /etc/burp/burp-server.conf

# if burp-ui client configuration doesn't exist, add
if [ ! -f /etc/burp/clientconfdir/${BUI_USER} ]; then
	# Burp client conf - client side
	cat << EOF > /etc/burp/burp.conf
# Burp client
mode = client
port = 4971
status_port = 4972
server = 127.0.0.1
password = ${BUI_USER_PASSWORD}
cname = ${BUI_USER}
pidfile = /var/run/burp.bui.pid
syslog = 0
stdout = 1
progress_counter = 1
network_timeout = 72000
ca_burp_ca = /usr/sbin/burp_ca
ca_csr_dir = /etc/burp/CA-client
# SSL certificate authority - same file on both server and client
ssl_cert_ca = /etc/burp/ssl_cert_ca-client.pem
# Client SSL certificate
ssl_cert = /etc/burp/ssl_cert-client.pem
# Client SSL key
ssl_key = /etc/burp/ssl_cert-client.key
# SSL key password
ssl_key_password = ${SSL_KEY_RANDOM_PASS}
# Common name in the certificate that the server gives us
ssl_peer_cn = burpserver
# The following options specify exactly what to backup.
include = /etc
include = /home
EOF
	# Burp client conf - server side
	cat << EOF > /etc/burp/clientconfdir/${BUI_USER}
password = ${BUI_USER_PASSWORD}
EOF
fi

# Burp-UI config
sed -i "s|^admin = .\+|admin = ${WEBUI_ADMIN_PASSWORD}|" /etc/burp/burpui.cfg
sed -i "s|^appsecret = .\+random|appsecret = ${APPSECRET_RANDOM_PASS}|" /etc/burp/burpui.cfg
sed -i "s|^tmpdir = .\+|tmpdir = ${RESTOREPATH}|" /etc/burp/burpui.cfg

# Burp notify
if [[ $NOTIFY_FAILURE == "true" ]]; then
	sed -i 's/^#notify_failure/notify_failure/g' /etc/burp/burp-server.conf
	sed -i "s/To:youremail@example.com/To:${NOTIFY_EMAIL}/g" /etc/burp/burp-server.conf
else
	sed -i 's/^notify_failure/#notify_failure/g' /etc/burp/burp-server.conf
fi

if [[ $NOTIFY_SUCCESS == "true" ]]; then
	sed -i 's/^#notify_success/notify_success/g' /etc/burp/burp-server.conf
	sed -i "s/To:youremail@example.com/To:${NOTIFY_EMAIL}/g" /etc/burp/burp-server.conf
else
	sed -i 's/^notify_success/#notify_success/g' /etc/burp/burp-server.conf
fi

# Burp Reports config
sed -i "s|__WEBUI_ADMIN_PASSWORD__|${WEBUI_ADMIN_PASSWORD}|g" /etc/burp/burp-reports.conf
sed -i "s|__NOTIFY_EMAIL__|${NOTIFY_EMAIL}|g" /etc/burp/burp-reports.conf
sed -i "s|__FROM_EMAIL__|${FROM_EMAIL}|g" /etc/burp/burp-reports.conf
sed -i "s|__MACHINENAME__|${MACHINENAME}|g" /etc/burp/burp-reports.conf

# Function to stop processes
function StopProcesses {
	while [ $(/usr/bin/monit status | sed -n '/^Process/{n;p;}' | awk '{print $2}' | grep -c OK) != 0 ] ; do
		sleep 2
		/usr/bin/monit stop all
	done
	exit 0
}

# Start services

# run StopProcesses function if docker stop is initiated
trap StopProcesses EXIT TERM

# start monit and all monitored processes
/usr/bin/monit && /usr/bin/monit start all

# just infinite loop
while true
do
	sleep 1d
done &

wait $!
