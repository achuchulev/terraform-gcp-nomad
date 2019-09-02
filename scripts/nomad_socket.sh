#!/usr/bin/env bash

[ -f /etc/nginx/sites-available/default ] && { BACKEND_SOCKET=`sudo cat /etc/nginx/sites-available/default | grep 'upstream nomad_backend'`
    if [ '${BACKEND_SOCKET}' == '' ]; 
        then 
            sudo -E bash -c 'echo upstream nomad_backend { $OUT } >> /etc/nginx/sites-available/default' 
        else 
            sed -i 's/${BACKEND_SOCKET}/upstream nomad_backend { $OUT }/g' /etc/nginx/sites-available/default
    fi 
}