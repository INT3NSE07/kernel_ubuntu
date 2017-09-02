#!/bin/bash

# red = errors, cyan = warnings, green = confirmations, blue = informational
# plain for generic text, bold for titles, reset flag at each end of line
CLR_RST=$(tput sgr0)                        ## reset flag
CLR_RED=$CLR_RST$(tput setaf 1)             #  red, plain
CLR_GRN=$CLR_RST$(tput setaf 2)             #  green, plain
CLR_BLU=$CLR_RST$(tput setaf 4)             #  blue, plain
CLR_CYA=$CLR_RST$(tput setaf 6)             #  cyan, plain
CLR_BLD=$(tput bold)                        ## bold flag
CLR_BLD_RED=$CLR_RST$CLR_BLD$(tput setaf 1) #  red, bold
CLR_BLD_GRN=$CLR_RST$CLR_BLD$(tput setaf 2) #  green, bold
CLR_BLD_BLU=$CLR_RST$CLR_BLD$(tput setaf 4) #  blue, bold
CLR_BLD_CYA=$CLR_RST$CLR_BLD$(tput setaf 6) #  cyan, bold

# Check number of threads
THREADS=$(cat /proc/cpuinfo | grep '^processor' | wc -l)

# Reset tree
git reset --hard

# Check the starting time
TIME_START=$(date +%s.%N)

# Root
if [ $EUID != 0 ]; then
    echo -e "Script requires root access"
    sudo "$0" "$@"
    exit $?
fi

# Clean up
rm -rf /tmp/kernobj
make mrproper -j16 -i

# Copy defconfig
cp defconfig .config

# Start build
echo -e "${CLR_BLD_BLU}Starting compilation${CLR_RST}"

# Build the kernel and modules
make -j"$((THREADS * 2+2))"
make modules

# Build successful!
RETVAL=0
choice=y

# Check if the build failed
if [ $RETVAL -ne 0 ]; then
        echo "${CLR_BLD_RED}Build failed!"
        echo -e ""
	choice=n
fi

# Check the finishing time
TIME_END=$(date +%s.%N)

# Total time taken
echo -e "${CLR_BLD_GRN}Total time elapsed:${CLR_RST} ${CLR_GRN}$(echo "($TIME_END - $TIME_START) / 60" | bc) minutes ($(echo "$TIME_END - $TIME_START" | bc) seconds)${CLR_RST}"

# Install the kernel
case "$choice" in
	y )
	        make modules_install
		make install
		update-grub
		;;
esac

# Remove all the addtional generated files
git reset --hard
git clean -fd

echo -e "${CLR_BLD_GRN}Done.${CLR_RST}"
