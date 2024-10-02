#!/bin/sh

if [ -z "$API_PASSWORD" ]; then
  echo "No API_PASSWORD found"
  API_PASSWORD=$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)
fi

if [ -z "$ADMIN_PASSWORD" ]; then
  echo "No ADMIN_PASSWORD found"
  ADMIN_PASSWORD=$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)
fi

if [ ! -e /etc/nut/ups.conf ]; then
  echo "Default ups.conf created"
  cat >/etc/nut/ups.conf <<EOF
[$UPS_NAME]
	desc = "$UPS_DESC"
	driver = $UPS_DRIVER
	port = $UPS_PORT
EOF
else
  echo "Skipped ups.conf config"
fi

if [ ! -e /etc/nut/upsd.conf ]; then
  echo "Default upsd.conf created"
  cat >/etc/nut/upsd.conf <<EOF
LISTEN ${API_ADDRESS:-0.0.0.0} ${API_PORT:-3493}
EOF
else
  echo "Skipped upsd.conf config"
fi

if [ ! -e /etc/nut/upsd.users ]; then
  echo "Default upsd.users created"
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
  echo "Skipped upsd.users config"
fi

if [ ! -e /etc/nut/upsmon.conf ]; then
  echo "Default upsmon.conf created"
  cat >/etc/nut/upsmon.conf <<EOF
MONITOR $UPS_NAME@localhost 1 monitor $API_PASSWORD master
SHUTDOWNCMD "$SHUTDOWN_CMD"
EOF
else
  echo "Skipped upsmon.conf config"
fi

chgrp -R nut /etc/nut /dev/bus/usb
chmod -R o-rwx /etc/nut

/usr/sbin/upsdrvctl start
/usr/sbin/upsd
exec /usr/sbin/upsmon -D
