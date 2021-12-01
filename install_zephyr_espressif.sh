# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 Robert Connaghan (burtrum)
#
# @file install_zephyr_espressif.sh
#
# Installs full Zephyr virtual environment for Espressif ESP32 SOC development.
# Zephyr's Espressif SOC support is a work in progress.
#
# This will allow you to build included Zephyr sample 'hello_world'.
# Successfully built for Espressif SOC: esp32, esp32c3, esp32s2.
# Flashed to esp32 and esp32s2 boards. Monitored serial port.
#
# The entire install takes a very, very long time.
# Asks for 'sudo password' at the very begining!
# Asks for 'sudo password' at the very end!
#
# This single script installs everything with minimal interaction for a couple of *sudo passwords*.
# 1. Install Zephyr Linux prerequisites, with latest Kitware CMake.
# 2. Install Python Virtual Environment (venv).
# 3. Install Zyphyr Part 1: Zephyr SDK.
# 4. Install Zyphyr Part 2: Zephyr Project Files.
# 5. Install Zyphyr Part 3: Add Espressif ESP32 SDK tools including RISCV.
#    When released, the Espressif SDK should be included in the Zephyr SDK.
# 6. OpenOCD udev defines for USB access. Untested.
# 7. Shell activate scripts for esp32, esp32s2, esp32c3.
#
# 8. Known issue temporary fix. Install 'python2.7-dev' required for GDB.
#       If needed comment out and live with warnings: apt-get install python2.7-dev
#
### Get and run install script `install_zephyr_espressif.sh`
#
# git clone https://github.com/burtrum/scripts-zephyr
#
# Run script without logging: Send stdout and stderr to console
#   $ chmod +x ./install_zephyr_espressif.sh
#   $ ./install_zephyr_espressif.sh
#
# Run script with logging: Send stdout and stderr to console and local BIG log file.
#   $ chmod +x ./install_zephyr_espressif.sh
#   $ ./install_zephyr_espressif.sh 2>&1 | tee -a ./console_log.txt
#   $ cat ./console_log.txt | grep -i error
#   $ cat ./console_log.txt | grep -i warn
#

### Modifiable
# Zephyr SDK version to install: change as needed. Tested: 0.13.1 and 0.13.2
# Zephyr SDK BIN location; no changes recommended.
Z_SDKVER=0.13.2
Z_SDKBIN=${HOME}/bin

# Zephyr Project location; no changes recommended.
Z_INSTALL=${HOME}/zephyrproject

echo
echo "Install Zephyr Project with Zephyr SDK, Espressif ESP32 support and Python Virtual Env."
echo
echo "Zephyr Project latest version at: ${Z_INSTALL}"
echo "Zephyr SDK version ${Z_SDKVER} at: ${Z_SDKBIN}"
echo
echo "This Zephyr/Espressif script requires entering 2 'sudo passwords'"
echo "... one right now at the begining and one at the very end."
echo "This takes a very long time. Very long."
echo

# Do not modify
ZEPHYR_TOOLCHAIN_VARIANT="espressif"
IDF_PATH=${Z_INSTALL}/modules/hal/${ZEPHYR_TOOLCHAIN_VARIANT}
ESPRESSIF_TOOLCHAIN_PATH="${HOME}/.espressif/tools/zephyr"
Z_SDKRUNSCRIPT="zephyr-sdk-${Z_SDKVER}-linux-x86_64-setup.run"

mkdir -p ${Z_SDKBIN}
mkdir -p ${HOME}/.local/bin
mkdir -p ${HOME}/bin
rm -f ./console_log.txt

# 1. Install Zephyr Linux prerequisites, with latest Kitware CMake.
#    Added `python3.8-venv` to run Zephyr west tools in a venv.
rm -f ./kitware-archive.sh
wget --no-verbose https://apt.kitware.com/kitware-archive.sh
sudo bash ./kitware-archive.sh

# CLEAN-UP
rm -f ./kitware-archive.sh

sudo apt-get --quiet  --yes --no-install-recommends install \
	ccache \
	cmake \
	dfu-util \
	device-tree-compiler \
	file \
	gcc \
	gcc-multilib \
	g++-multilib \
	git \
	gperf \
	libpython3.8-dev \
	libsdl2-dev \
	make \
	ninja-build \
	python3-dev \
	python3-pip \
	python3-setuptools \
	python3-tk \
	python3-wheel \
	python3.8-venv \
	wget \
	xz-utils

## 8: workaround for GDB, waiting on better fix.
# Comment out if it causes trouble.
sudo apt-get --quiet  --yes --no-install-recommends install python2.7-dev

# 2. Install Python Virtual Environment (venv) into ${Z_INSTALL}.
# Activate Python Virtual Environment for rest of install.
# Side effect: creates ${Z_INSTALL} before `west init` would normally.
#
python3 -m venv ${Z_INSTALL}/.venv
source ${Z_INSTALL}/.venv/bin/activate
# Now in Python Virtual Environment

# 3. Install Zyphyr Part 1: Zephyr SDK
# FYI: Z_SDKRUNSCRIPT="zephyr-sdk-0.13.2-linux-x86_64-setup.run"
wget --no-verbose https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${Z_SDKVER}/${Z_SDKRUNSCRIPT}
chmod +x ./${Z_SDKRUNSCRIPT}
./${Z_SDKRUNSCRIPT} -- -d ${Z_SDKBIN}/zephyr-sdk-${Z_SDKVER}

# CLEAN-UP
rm -f ./${Z_SDKRUNSCRIPT}

# 4. Install Zyphyr Part 2: Zephyr Project Files.
# Install `west` for Zephyr Project management; needed `wheel` for unknown reason under venv.
# `west init` Zephyr Project directory from github, update, and install python requirements
#
pip3 install wheel
pip3 install west

west init ${Z_INSTALL}
cd ${Z_INSTALL}
west update
pip3 install -r ${Z_INSTALL}/zephyr/scripts/requirements.txt

# 5. Install Zyphyr Part 3: Add Espressif ESP32 SDK tools including RISCV.
west espressif install
west update
west espressif update

# update cmake data; Q: is this the right, the best place for this export command?
west zephyr-export

# 6. OpenOCD udev defines for USB access. Untested.
# Fof OCD/JTAG devices
sudo cp ${Z_SDKBIN}/zephyr-sdk-${Z_SDKVER}/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload

# CLEAN-UP Espressif SDK install files: *.tar.gz
rm -f ${HOME}/.espressif/dist/*

####################################
# Zephyr Project Installation with
# Espressif support is now done.
####################################

#
# Following ugly code creates helper scripts.
#

# 7. Shell activate scripts for esp32, esp32s2, esp32c3.
# Create an activation script for each Espressif SOC.
# Each Zephyr virtual development environment needs.
# 1. Activate python virtual environment
# 2. Set ${ZEPHYR_TOOLCHAIN_VARIANT}, ${ESPRESSIF_TOOLCHAIN_PATH}, ${IDF_PATH}.
# 3. Set ${PATH} with SOC specific build tools.
# Ready to develop!
# 'deactivate' to exit virtual development envivronment.
#

# 1 of 3: ESP32: Run as: 'source z_esp32.sh'
Z_ESP32=${HOME}/bin/z_esp32.sh
rm -f ${Z_ESP32}
touch ${Z_ESP32} && chmod +x ${Z_ESP32}
#
echo "# ${Z_ESP32}: Zephyr activate script for ESP32" >> ${Z_ESP32}
echo "# SPDX-License-Identifier: Apache-2.0" >> ${Z_ESP32}
echo "# SPDX-FileCopyrightText: 2021 burtrum" >> ${Z_ESP32}
echo "#" >> ${Z_ESP32}
echo "source ${Z_INSTALL}/.venv/bin/activate" >> ${Z_ESP32}
echo "export ZEPHYR_TOOLCHAIN_VARIANT=${ZEPHYR_TOOLCHAIN_VARIANT}" >> ${Z_ESP32}
echo "export ESPRESSIF_TOOLCHAIN_PATH=${ESPRESSIF_TOOLCHAIN_PATH}" >> ${Z_ESP32}
echo "export IDF_PATH=${IDF_PATH}" >> ${Z_ESP32}
# SOC specific
echo "export PATH=${ESPRESSIF_TOOLCHAIN_PATH}/xtensa-esp32-elf/bin:$PATH" >> ${Z_ESP32}
echo "echo \"Now developing for esp32 SOC\"" >> ${Z_ESP32}
echo "# EOF" >> ${Z_ESP32}


# 2 of 3: ESP32S2: Run as: 'source z_esp32s2.sh'
Z_ESP32S2=${HOME}/bin/z_esp32s2.sh
rm -f ${Z_ESP32S2}
touch ${Z_ESP32S2} && chmod +x ${Z_ESP32S2}
#
echo "# ${Z_ESP32S2}: Zephyr activate script for ESP32S2" >> ${Z_ESP32S2}
echo "# SPDX-License-Identifier: Apache-2.0" >> ${Z_ESP32S2}
echo "# SPDX-FileCopyrightText: 2021 burtrum" >> ${Z_ESP32S2}
echo "#" >> ${Z_ESP32S2}
echo "source ${Z_INSTALL}/.venv/bin/activate" >> ${Z_ESP32S2}
echo "export ZEPHYR_TOOLCHAIN_VARIANT=${ZEPHYR_TOOLCHAIN_VARIANT}" >> ${Z_ESP32S2}
echo "export ESPRESSIF_TOOLCHAIN_PATH=${ESPRESSIF_TOOLCHAIN_PATH}" >> ${Z_ESP32S2}
echo "export IDF_PATH=${IDF_PATH}" >> ${Z_ESP32S2}
# SOC specific
echo "export PATH=${ESPRESSIF_TOOLCHAIN_PATH}/xtensa-esp32s2-elf/bin:$PATH" >> ${Z_ESP32S2}
echo "echo \"Now developing for esp32s2 SOC\"" >> ${Z_ESP32S2}
echo "# EOF" >> ${Z_ESP32S2}


# 3 of 3: ESP32C3: Run as: 'source z_esp32c3.sh'
Z_ESP32C3=${HOME}/bin/z_esp32c3.sh
rm -f ${Z_ESP32C3}
touch ${Z_ESP32C3} && chmod +x ${Z_ESP32C3}
#
echo "# ${Z_ESP32C3}: Zephyr activate script for RISCV32 based ESP32C3" >> ${Z_ESP32C3}
echo "# SPDX-License-Identifier: Apache-2.0" >> ${Z_ESP32C3}
echo "# SPDX-FileCopyrightText: 2021 burtrum" >> ${Z_ESP32C3}
echo "#" >> ${Z_ESP32C3}
echo "source ${Z_INSTALL}/.venv/bin/activate" >> ${Z_ESP32C3}
echo "export ZEPHYR_TOOLCHAIN_VARIANT=${ZEPHYR_TOOLCHAIN_VARIANT}" >> ${Z_ESP32C3}
echo "export IDF_PATH=${IDF_PATH}" >> ${Z_ESP32C3}
# SOC specific
echo "export PATH=${ESPRESSIF_TOOLCHAIN_PATH}/riscv32-esp-elf/bin:$PATH" >> ${Z_ESP32C3}
echo "echo \"Now developing for esp32c3 SOC\"" >> ${Z_ESP32C3}
echo "# EOF" >> ${Z_ESP32C3}


# Closing output directions
echo
echo 'Try this Demo flow... do not copy the Linux venv prompts!'
echo
echo '  note: source one SOC environment: esp32, esp32c3 or esp32s2'
echo
echo '    $ source z_esp32.sh'
echo '    Now developing for esp32s2 SOC'
echo
echo '  note: now in python (.venv) development environment'
echo
echo '    (.venv) $ cd ~/zephyrproject/zephyr/samples/hello_world'
echo
echo '  note: The first build only does Kconfig and sets board, no compile. Just quit Kconfig menu pop-up.'
echo
echo '    (.venv) $ west build --pristine always --target menuconfig --board esp32'
echo
echo '  note: all following builds actually compile to the binary zephyr.elf and zephyr.bin'
echo
echo '    (.venv) $ west build --pristine auto'
echo
echo '  note: defaults to /dev/ttyUSB0'
echo
echo '    (.venv) $ west flash --esp-device /dev/ttyUSB0'
echo
echo '  note: <CTRL+]> to exit monitor:'
echo
echo '    (.venv) $ west espressif -p /dev/ttyUSB0 monitor'
echo

#EOF
