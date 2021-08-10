#!/bin/bash

set -e
#
# Reference - https://github.com/TremoloSecurity/apacheds/blob/master/run_apacheds.sh
#

# Start server.
service apacheds-2.0.0-M24-default start

# Wait until ApacheDS service started and listens on port 10389.
while [ -z "`netstat -tln | grep 10389`" ]; do
  echo 'Waiting for LDAP server to start ...'
  sleep 1
done
echo 'ApacheDS started.'
sleep 10

# Configure Keystore
echo 'Starting TLS...'

ldapmodify -h 127.0.0.1 -p 10389 -D uid=admin,ou=system -w secret <<EOF
dn: ads-serverId=ldapServer,ou=servers,ads-directoryServiceId=default,ou=config
changeType: modify
replace: ads-keystoreFile
ads-keystoreFile: /etc/ssl/certs/${KUBERNETES_SERVICE_NAME}.${MY_POD_NAMESPACE}.jks
-
replace: ads-certificatePassword
ads-certificatePassword: $APACHEDS_TLS_KS_PWD
-
EOF

# Change default password
echo 'Setting admin password'

ldapmodify -h 127.0.0.1 -p 10389 -D uid=admin,ou=system -w secret <<EOF
dn: uid=admin,ou=system
changeType: modify
replace: userPassword
userPassword: $APACHEDS_ROOT_PASSWORD
-
EOF

echo 'Configuration successful ...'
echo 'Restarting LDAP server for settings to apply ...'
service apacheds-2.0.0-M24-default stop
sleep 30
echo 'Boot to console...'
service apacheds-2.0.0-M24-default console