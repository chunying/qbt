#!/bin/sh

## create group
if ! grep '^qbt:' /etc/group > /dev/null 2>&1; then
	groupadd -g ${USER_GID} -o qbt
fi

## create user
if ! grep '^qbt:' /etc/passwd > /dev/null 2>&1; then
	useradd -M -g ${USER_GID} -u ${USER_UID} -s /bin/bash -o qbt
fi

## minimal user setup if necessary
chown "${USER_UID}:${USER_GID}" /home/qbt
if [ ! -f /home/qbt/.bashrc ]; then
	if [ -d /etc/skel ]; then cp /etc/skel/.* /home/qbt/; fi
	chown "${USER_UID}:${USER_GID}" /home/qbt/.[a-z]*
fi

## launch vpn
if ls /etc/wireguard/*.conf; then
	_IF=`/bin/ls /etc/wireguard/*.conf | sort | head -n 1`
        resolvconf -u
	wg-quick up ${_IF}
fi

exec su qbt -c \
  '/usr/bin/qbittorrent-nox --webui-port=9080 --profile=/home/qbt --add-stopped=false'
exec sleep infinity
