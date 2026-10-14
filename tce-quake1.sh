#!/bin/sh

tce-load -wi Xorg-7.7-3d.tcz
tce-load -wi compiletc
tce-load -wi sdl2.tcz
tce-load -wi SDL2-dev
# tce-load -wi alsa.tcz
# tce-load -wi alsa-modules-KERNEL.tcz
tce-load -wi libvorbis
tce-load -wi libmad-dev
# Установка движка
wget https://github.com/sezero/quakespasm/archive/refs/heads/master.tar.gz
tar -xzf master.tar.gz

# Установка id1 (файлы игры)
wget https://raw.githubusercontent/Keksiki12/alt/main/PAK0.PAK
