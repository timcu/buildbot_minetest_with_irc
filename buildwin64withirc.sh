#!/bin/bash
set -e

{
echo -n "Start of compilation: "; date -R

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ $# -ne 1 ]; then
   echo "Usage: $0 <build directory>"
   exit 1
fi
builddir=$1
mkdir -p $builddir
builddir="$( cd "$builddir" && pwd )"
packagedir=$builddir/packages
libdir=$builddir/libs

toolchain_file=$dir/toolchain_mingw64.cmake
irc_patch=$dir/ircinitlua.patch
irrlicht_version=1.8.4
ogg_version=1.3.2
vorbis_version=1.3.5
curl_version=7.54.0
gettext_version=0.19.8.1
freetype_version=2.8
sqlite3_version=3.19.2
luajit_version=2.1.0-beta3
leveldb_version=1.19
zlib_version=1.2.11

mkdir -p $packagedir
mkdir -p $libdir

cd $builddir

# Get stuff
[ -e $packagedir/irrlicht-$irrlicht_version.zip ] || wget http://minetest.kitsunemimi.pw/irrlicht-$irrlicht_version-win64.zip \
   -c -O $packagedir/irrlicht-$irrlicht_version.zip
[ -e $packagedir/zlib-$zlib_version.zip ] || wget http://minetest.kitsunemimi.pw/zlib-$zlib_version-win64.zip \
   -c -O $packagedir/zlib-$zlib_version.zip
[ -e $packagedir/libogg-$ogg_version.zip ] || wget http://minetest.kitsunemimi.pw/libogg-$ogg_version-win64.zip \
   -c -O $packagedir/libogg-$ogg_version.zip
[ -e $packagedir/libvorbis-$vorbis_version.zip ] || wget http://minetest.kitsunemimi.pw/libvorbis-$vorbis_version-win64.zip \
   -c -O $packagedir/libvorbis-$vorbis_version.zip
[ -e $packagedir/curl-$curl_version.zip ] || wget http://minetest.kitsunemimi.pw/curl-$curl_version-win64.zip \
   -c -O $packagedir/curl-$curl_version.zip
[ -e $packagedir/gettext-$gettext_version.zip ] || wget http://minetest.kitsunemimi.pw/gettext-$gettext_version-win64.zip \
   -c -O $packagedir/gettext-$gettext_version.zip
[ -e $packagedir/freetype2-$freetype_version.zip ] || wget http://minetest.kitsunemimi.pw/freetype2-$freetype_version-win64.zip \
   -c -O $packagedir/freetype2-$freetype_version.zip
[ -e $packagedir/sqlite3-$sqlite3_version.zip ] || wget http://minetest.kitsunemimi.pw/sqlite3-$sqlite3_version-win64.zip \
   -c -O $packagedir/sqlite3-$sqlite3_version.zip
#[ -e $packagedir/luajit-$luajit_version.zip ] || wget http://minetest.kitsunemimi.pw/luajit-$luajit_version-win64.zip \
#   -c -O $packagedir/luajit-$luajit_version.zip
[ -e $packagedir/luajit-$luajit_version.zip ] || wget http://luajit.org/download/LuaJIT-$luajit_version.zip \
   -c -O $packagedir/luajit-$luajit_version.zip
[ -e $packagedir/libleveldb-$leveldb_version.zip ] || wget http://minetest.kitsunemimi.pw/libleveldb-$leveldb_version-win64.zip \
   -c -O $packagedir/libleveldb-$leveldb_version.zip
[ -e $packagedir/openal_stripped.zip ] || wget http://minetest.kitsunemimi.pw/openal_stripped64.zip \
   -c -O $packagedir/openal_stripped.zip


# Extract stuff
cd $libdir
[ -d irrlicht ] || unzip -o $packagedir/irrlicht-$irrlicht_version.zip -d irrlicht
[ -d zlib ] || unzip -o $packagedir/zlib-$zlib_version.zip -d zlib
[ -d libogg ] || unzip -o $packagedir/libogg-$ogg_version.zip -d libogg
[ -d libvorbis ] || unzip -o $packagedir/libvorbis-$vorbis_version.zip -d libvorbis
[ -d libcurl ] || unzip -o $packagedir/curl-$curl_version.zip -d libcurl
[ -d gettext ] || unzip -o $packagedir/gettext-$gettext_version.zip -d gettext
[ -d freetype ] || unzip -o $packagedir/freetype2-$freetype_version.zip -d freetype
[ -d sqlite3 ] || unzip -o $packagedir/sqlite3-$sqlite3_version.zip -d sqlite3
[ -d openal_stripped ] || unzip -o $packagedir/openal_stripped.zip
[ -d luajit ] || unzip -o $packagedir/luajit-$luajit_version.zip -d luajit-tmp
[ -d leveldb ] || unzip -o $packagedir/libleveldb-$leveldb_version.zip -d leveldb
[ -d luasocket ] || git clone https://github.com/diegonehab/luasocket.git
[ -d irc ] || git clone --recursive https://github.com/minetest-mods/irc.git

# Build luajit
[ -d luajit-tmp/LuaJIT-$luajit_version ] && mv luajit-tmp/LuaJIT-$luajit_version ./luajit && rmdir luajit-tmp
cd luajit
mingw32-make amalg
cd ..

# Build luasocket
cd luasocket
export LUAV=5.1
export LUAINC_mingw=$libdir/luajit/src
export LUALIB_mingw=$libdir/luajit/src/lua51.dll
export CDIR_mingw=lua/$LUAV
export LDIR_mingw=lua/$LUAV/lua
mingw32-make mingw
mkdir -p socket-lib/mime socket-lib/socket
cd socket-lib
cp ../src/*.lua socket/
cp ../src/mime*.dll mime/core.dll
cp ../src/socket*.dll socket/core.dll
mv socket/ltn12.lua .
mv socket/socket.lua .
mv socket/mime.lua .
cd ../..

# Get minetest
cd $builddir
if [ ! "x$EXISTING_MINETEST_DIR" = "x" ]; then
   ln -s $EXISTING_MINETEST_DIR minetest
else
   [ -d minetest ] && (cd minetest && git checkout master && git pull) || (git clone https://github.com/minetest/minetest)
fi
cd minetest
if [ ! "x$MINETEST_RELEASE" = "x" ]; then
	git checkout $MINETEST_RELEASE
fi
git_hash=$(git rev-parse --short HEAD)

# Get minetest_game
cd games
if [ "x$NO_MINETEST_GAME" = "x" ]; then
   [ -d minetest_game ] && (cd minetest_game && git pull) || (git clone https://github.com/minetest/minetest_game)
fi
cd ../..

# Build the thing
cd minetest
[ -d _build ] && rm -Rf _build/
mkdir _build
cd _build
mv /usr/bin/sh.exe /usr/bin/sh.exe~

cmake .. \
   -G"MinGW Makefiles" \
   -DCMAKE_AR=/mingw64/x86_64-w64-mingw32/bin/ar \
   -DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
   -DCMAKE_INSTALL_PREFIX=/tmp \
   -DVERSION_EXTRA=$git_hash-irc \
   -DBUILD_CLIENT=1 -DBUILD_SERVER=0 \
   \
   -DENABLE_SOUND=1 \
   -DENABLE_CURL=1 \
   -DENABLE_GETTEXT=1 \
   -DENABLE_FREETYPE=1 \
   -DENABLE_LEVELDB=1 \
   \
   -DIRRLICHT_INCLUDE_DIR=$libdir/irrlicht/include \
   -DIRRLICHT_LIBRARY=$libdir/irrlicht/lib/Win64-gcc/libIrrlicht.dll.a \
   -DIRRLICHT_DLL=$libdir/irrlicht/bin/Win64-gcc/Irrlicht.dll \
   \
   -DZLIB_INCLUDE_DIR=$libdir/zlib/include \
   -DZLIB_LIBRARIES=$libdir/zlib/lib/libz.dll.a \
   -DZLIB_DLL=$libdir/zlib/bin/zlib1.dll \
   \
   -DLUA_INCLUDE_DIR=$libdir/luajit/src \
   -DLUA_LIBRARY=$libdir/luajit/src/lua51.dll \
   -DLUA_DLL=$libdir/luajit/src/lua51.dll \
   \
   -DOGG_INCLUDE_DIR=$libdir/libogg/include \
   -DOGG_LIBRARY=$libdir/libogg/lib/libogg.dll.a \
   -DOGG_DLL=$libdir/libogg/bin/libogg-0.dll \
   \
   -DVORBIS_INCLUDE_DIR=$libdir/libvorbis/include \
   -DVORBIS_LIBRARY=$libdir/libvorbis/lib/libvorbis.dll.a \
   -DVORBIS_DLL=$libdir/libvorbis/bin/libvorbis-0.dll \
   -DVORBISFILE_LIBRARY=$libdir/libvorbis/lib/libvorbisfile.dll.a \
   -DVORBISFILE_DLL=$libdir/libvorbis/bin/libvorbisfile-3.dll \
   \
   -DOPENAL_INCLUDE_DIR=$libdir/openal_stripped/include/AL \
   -DOPENAL_LIBRARY=$libdir/openal_stripped/lib/libOpenAL32.dll.a \
   -DOPENAL_DLL=$libdir/openal_stripped/bin/OpenAL32.dll \
   \
   -DCURL_DLL=$libdir/libcurl/bin/libcurl-4.dll \
   -DCURL_INCLUDE_DIR=$libdir/libcurl/include \
   -DCURL_LIBRARY=$libdir/libcurl/lib/libcurl.dll.a \
   \
   -DGETTEXT_MSGFMT=`which msgfmt` \
   -DGETTEXT_DLL=$libdir/gettext/bin/libintl-8.dll \
   -DGETTEXT_ICONV_DLL=$libdir/gettext/bin/libiconv-2.dll \
   -DGETTEXT_INCLUDE_DIR=$libdir/gettext/include \
   -DGETTEXT_LIBRARY=$libdir/gettext/lib/libintl.dll.a \
   \
   -DFREETYPE_INCLUDE_DIR_freetype2=$libdir/freetype/include/freetype2 \
   -DFREETYPE_INCLUDE_DIR_ft2build=$libdir/freetype/include/freetype2 \
   -DFREETYPE_LIBRARY=$libdir/freetype/lib/libfreetype.dll.a \
   -DFREETYPE_DLL=$libdir/freetype/bin/libfreetype-6.dll \
   \
   -DSQLITE3_INCLUDE_DIR=$libdir/sqlite3/include \
   -DSQLITE3_LIBRARY=$libdir/sqlite3/lib/libsqlite3.dll.a \
   -DSQLITE3_DLL=$libdir/sqlite3/bin/libsqlite3-0.dll \
   \
   -DLEVELDB_INCLUDE_DIR=$libdir/leveldb/include \
   -DLEVELDB_LIBRARY=$libdir/leveldb/lib/libleveldb.dll.a \
   -DLEVELDB_DLL=$libdir/leveldb/bin/libleveldb.dll

mv /usr/bin/sh.exe~ /usr/bin/sh.exe
mingw32-make package -j$(nproc)

cd _CPack_Packages/win64/ZIP/minetest-*/
cpackdir=`pwd`
minetestname=`basename $cpackdir`
bindir="$cpackdir/bin"
modsdir="$cpackdir/mods"
cp /mingw64/bin/libgcc_s_seh-1.dll $bindir/
cp /mingw64/bin/libstdc++-6.dll $bindir/
cp /mingw64/bin/libwinpthread-1.dll $bindir/
cp $libdir/luasocket/src/*.dll $bindir/
cp -R $libdir/irc $modsdir/
patch $modsdir/irc/init.lua $dir/ircinitlua.patch
cp -R $libdir/luasocket/socket-lib $modsdir/irc/
# Following line only required for builds of minetest releases earlier than 19-Jul-2017 which includes 0.4.16
[ -e $bindir/lua51.dll ] || cp $libdir/luajit/src/lua51.dll $bindir/

cd $cpackdir/..
zip -ur $minetestname.zip $minetestname
cp $minetestname.zip ../../../

echo -n "End of compilation: "; date -R

} |& tee build.log

# EOF
 
