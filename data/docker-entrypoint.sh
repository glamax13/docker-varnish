#!/usr/bin/env bash

set -e
set -o pipefail


###
### Default user/group id
###
MY_UID=101
MY_GID=101

if env | grep '^NEW_UID='; then
	MY_UID="$( env | grep '^NEW_UID=' | sed 's/^NEW_UID=//g' )"
fi
if env | grep '^NEW_GID='; then
	MY_GID="$( env | grep '^NEW_GID=' | sed 's/^NEW_GID=//g' )"
fi

###
### Change uid/gid
###
usermod -u "$MY_UID" "varnish"
groupmod -g "$MY_GID" "varnish"


###
### Configure bundled default varnish config
###

# Extract Varnish version
# shellcheck disable=SC2034
VARNISH_VERSION="$( varnishd -V 2>&1 | grep -Eo 'varnish-[.0-9]+' | sed 's/varnish-/Varnish /g' )"

for name in BACKEND_PORT BACKEND_HOST VARNISH_VERSION
do
	eval value=\$$name
	# shellcheck disable=SC2154
	sed -i "s|\${${name}}|${value}|g" /etc/varnish/default.vcl
done


###
### Start Varnish
###
exec bash -c \
	"exec varnishd \
	-a :6081 \
	-T localhost:6082 \
	-F \
	-f $VARNISH_CONFIG \
	-s malloc,$CACHE_SIZE \
	$VARNISHD_PARAMS"
