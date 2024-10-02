#!/bin/sh

if [ -z "$API_PASSWORD" ]; then
  printf "No API_PASSWORD found"
  API_PASSWORD=$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)
fi

if [ -z "$ADMIN_PASSWORD" ]; then
  printf "No ADMIN_PASSWORD found"
  ADMIN_PASSWORD=$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)
fi

if [ ! -e /etc/nut/ups.conf ]; then
  printf "Default ups.conf created"
  cat >/etc/nut/ups.conf <<EOF
[$UPS_NAME]
	desc = "$UPS_DESC"
	driver = $UPS_DRIVER
	port = $UPS_PORT
EOF
else
  printf "Skipped ups.conf config"
fi

if [ ! -e /etc/nut/upsd.conf ]; then
  printf "Default upsd.conf created"
  cat >/etc/nut/upsd.conf <<EOF
LISTEN ${API_ADDRESS:-0.0.0.0} ${API_PORT:-3493}
EOF
else
  printf "Skipped upsd.conf config"
fi

if [ ! -e /etc/nut/upsd.users ]; then
  printf "Default upsd.users created"
  cat >/etc/nut/upsd.users <<EOF
[admin]
	password = $ADMIN_PASSWORD
	actions = set
	actions = fsd
	instcmds = all

[monitor]
	password = $API_PASSWORD
	upsmon master
EOF
else
  printf "Skipped upsd.users config"
fi

if [ ! -e /etc/nut/upsmon.conf ]; then
  printf "Default upsmon.conf created"
  cat >/etc/nut/upsmon.conf <<EOF
MONITOR $UPS_NAME@localhost 1 monitor $API_PASSWORD master
SHUTDOWNCMD "$SHUTDOWN_CMD"
EOF
else
  printf "Skipped upsmon.conf config"
fi

chgrp -R nut /etc/nut /dev/bus/usb
chmod -R o-rwx /etc/nut

/usr/sbin/upsdrvctl start
/usr/sbin/upsd
exec /usr/sbin/upsmon -D
