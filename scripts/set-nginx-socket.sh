#!/usr/bin/env bash

# set nginx backend upstream sockets
[ -f /etc/nginx/sites-available/default ] && { BACKEND_SOCKET=`sudo cat /etc/nginx/sites-available/default | grep 'upstream nomad_backend'`
    if [ "${BACKEND_SOCKET}" == "" ];
        then
            echo "upstream nomad_backend { $1 }" >> /etc/nginx/sites-available/default
        else
            sed -i "s/${BACKEND_SOCKET}/upstream nomad_backend { $1 }/g" /etc/nginx/sites-available/default
    fi
}
