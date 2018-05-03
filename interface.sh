#!/bin/bash

case $(uname) in
    Darwin)
        route -n get default|grep interface|awk  '{print $2}'
        ;;
    Linux)
        ip route|grep default|awk '{print $5}'
        ;;
esac

