#!/bin/sh

tar -xzvf programs.tar.gz
for f in to-install/*; do
    pacman -U $f
done

tar -xzvf data.tar.gz
cp -r etc/* /etc/
