#!/bin/sh

tce-load -wi compiletc
tce-load -wi libtool
tce-load -wi automake
tce-load -wi autoconf
tce-load -wi bison
tce-load -wi flex

tce-load -wi Xorg-7.7-3d
tce-load -wi SDL2
tce-load -wi SDL2-dev
tce-load -wi libvorbis
tce-load -wi libvorbis-dev
tce-load -wi libogg
tce-load -wi libogg-dev

cd ~
wget "https://sourceforge.net/projects/quake/files/quakeforge-0.7.2.tar.bz2/download" -O quakeforge-0.7.2.tar.bz2
tar -xjf quakeforge-0.7.2.tar.bz2

