#!/bin/sh

tce-load -wi Xorg-7.7-3d.tcz
tce-load -wi compiletc
tce-load -wi sdl2.tcz
tce-load -wi SDL2-dev
# tce-load -wi alsa.tcz
# tce-load -wi alsa-modules-KERNEL.tcz
# tce-load -wi libvorbis
tce-load -wi libvorbis-dev
tce-load -wi libmad-dev

# Установка движка
wget https://github.com/sezero/quakespasm/archive/refs/heads/master.tar.gz
tar -xzf master.tar.gz

# Установка id1 (файлы игры)
wget https://raw.githubusercontent/Keksiki12/alt/main/PAK0.PAK
wget https://raw.githubusercontent/Keksiki12/AUlab/main/PAK1.PAK
#Сборка
mv PAK0.PAK pak0.pak
mv PAK1.PAK pak1.pak
cd quakespasm-master/Quake
make clean
make USE_SDL2=1
cd ~
mkdir quake
mkdir quake/id1
mv pak0.pak quake/id1/
mv pak1.pak quake/id1/
cp quakespasm-master/Quake/quakespasm quake/
cd ~/quake
