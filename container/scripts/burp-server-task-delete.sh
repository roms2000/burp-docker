#!/bin/sh
DELETE_DIRECTORY=$(cat /etc/burp/burp-server.conf | grep -E "^\s*manual_delete\s*=" | cut -d '=' -f 2 | sed 's|\s||g')
if [ "$(which realpath)" != "" ] && [ ! -z "${DELETE_DIRECTORY}" ] ; then
        DELETE_DIRECTORY=$( realpath ${DELETE_DIRECTORY} )
fi

echo "DELETE_DIRECTORY = ${DELETE_DIRECTORY}"

if [ -d "${DELETE_DIRECTORY}" ] && [ "${DELETE_DIRECTORY}" != "/" ] ; then
        find "${DELETE_DIRECTORY}" -maxdepth 1 -mindepth 1 -type d | while read line ; do
                echo "cd \"${DELETE_DIRECTORY}\" && rm -rf \"$line\""
                cd "${DELETE_DIRECTORY}" && rm -rf "$line"
        done
fi
echo "Burp server - task delete - done."
