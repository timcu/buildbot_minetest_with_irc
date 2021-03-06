# buildbot_minetest_with_irc

This script runs on msys2/mingw64 and builds a 64 bit windows version of minetest including the irc mod. 

See [\[Mod\] Internet Relay Chat (irc)](https://forum.minetest.net/viewtopic.php?f=11&t=3905&sid=1544b6daaac3a36c36646fceb2f0ac73&start=100#p213180) by kaeza for requirements to install irc mod in windows minetest.

See [\[Windows\] Building 64-bit minetest with MSYS2/mingw64](https://forum.minetest.net/viewtopic.php?f=42&t=17797) by Fixerol for how to set up msys2 to run this script.

Packages suggested by Fixerol (run in MSYS2 MinGW 64-bit)
```
pacman -S base-devel git unzip
pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake
```
Additional requirements. Install "patch" using pacman in MSYS2 MinGW 64-bit.
```
pacman -S patch zip
```
Install and run this script in MSYS2 MinGW 64-bit
```
git clone https://github.com/timcu/buildbot_minetest_with_irc.git
cd buildbot_minetest_with_irc
./buildwin64withirc.sh ../minetest_with_irc
```
The minetest package will be located in 
```
../minetest_with_irc/minetest/_build/
```
and will have a name like `minetest-5.1.0-cff1e9ca-irc-win64.zip`

If you want a version other than the latest snapshot set the shell environment variable MINETEST_RELEASE before running script.
```
export MINETEST_RELEASE=5.0.1
./buildwin64withirc.sh ../minetest_with_irc
```


