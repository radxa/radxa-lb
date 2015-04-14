#!/bin/sh

sed -i "s|172.168.1.3/||" /etc/apt/sources.list
sed -i "s|172.168.1.3/||" /etc/apt/sources.list.d/*.list
