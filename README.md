## Zephyr RTOS and Espressif ESP32 Development Setup

- One-script installs a full Linux Zephyr development environment for Espressif ESP32 SOCs.
- Demonstrate step-by-step a minimal Zephyr workflow from configure and compile to flash and monitor.

Using (venv) Python virtual environment brings easy switching between target SOCs. Execute a shell *activate* script to fully switch development between esp32, esp32s2 Xtensa, and esp32c3 RISCV environments.

This will allow you to test build and flash the Zephyr `hello_world` sample.
- Successfully built for Espressif SOC: esp32, esp32c3, esp32s2.
- Flashed to esp32 and esp32s2 boards. No esp32c3 board available.
- Monitored serial port.
- Building code outside of the Zephyr tree is not setup by this script. I am still learning.

Actual serial port output from last build monitor.
```
*** Booting Zephyr OS build v2.7.99-1819-ga6f932a194c3  ***
Hello World! esp32
```
### This step-by-step guide will show:
1. Download `scripts-zephyr` from github.
2. Change  Zephyr SDK version  and file locations.  Script Options.
3. Execute `install_zephyr_espressif.sh` script, with and without logging.


This single `scripts-zephyr` script installs everything with minimal interaction for a couple of *sudo passwords*.
1. Zephyr Linux prerequisites (general and specific).
2. Zephyr Project files.
3. Zephyr SDK - zephyr-sdk-0.13.2.
4. Python Virtual Environment (venv).
5. Espressif ESP32 SDK tools including RISCV.
6. OpenOCD udev defines for USB access. Untested.
7. Shell activate scripts for esp32, esp32s2, esp32c3.
8. Known issue temporary fix. Install 'python2.7-dev' required for GDB. GDB itself is still not tested.

> Python2.7 is s a bad quick fix for GDB issue. Comment out the "apt-get install python2.7-dev" line in script to prevent installation.
https://github.com/zephyrproject-rtos/zephyr/issues/39212

You will be able to perform a minimal Zephyr Workflow.
1. Select a target SOC build environment with *activate* script. Currently `esp32`, `esp32s2`, and `esp32c3`.
2. Select a target board. Tested with `esp32` and `esp32s2_saola` and no board to flash `esp32c3_devkitm`.
3. View *application* `Kconfig` configuration using *guiconfig* interface.
4. Build and flash a Zephyr *application* to a supported board serial port (USB).
5. Monitor the *application* console output from the board's serial port (USB).

Zephyr file structure explained with notes. Final ELF file, `zephyr.elf` location.

I have not done these yet.
1. Debugging with GDB & JTAG.
2. Modifying anything else.
3. Erased the entire flash.

>Zephyr's support of Espressif ESP32 SOCs is a work in progress. I wrote this so that more developers could *get right to it* and flash their first Zephyr application. Further work on a separate `esp32app` folder (*zephyr workspace?*) for my own zephyr development is moving along as fast as I can.

So *get right to it*.

### Download
```
git clone https://github.com/burtrum/scripts-zephyr
```

```
./scripts-zephyr
├── .git/
├── .gitignore
├── docs/
├── install_zephyr_espressif.sh
├── issues.txt
└── README.md
```

### Install
- In a terminal session within the `scripts-zephyr` directory.
- Run as a regular user at the Linux prompt. Prompt shown here as `$`.

> Asks for 'sudo password' once at the very end! And once at the very beginning. The entire install takes a very, very long time.

Send stdout and stderr to console. No log file.
```
$ chmod +x ./install_zephyr_espressif.sh
$ ./install_zephyr_espressif.sh
```
Send stdout and stderr to console and to a log file; check for errors.
```
$ chmod +x ./install_zephyr_espressif.sh
$ ./install_zephyr_espressif.sh 2>&1 | tee -a ./console_log.txt
$ grep -i error ./console_log.txt
$ grep -i warn  ./console_log.txt
```

##### Install a different Zephyr SDK version and  Script Options
1. Zephyr SDK set Z_SDKVER version. (numeric as 0.13.2)
2. Zephyr SDK at Z_SDKBIN location. (default ~/bin)
3. Zephyr Project at Z_INSTALL location. (default ~/zephyrproject)
4. Espressif SDK at `~/.espressif` location.
5. My activate scripts at `~/bin` location.

Current Zephyr install:
- https://github.com/zephyrproject-rtos/sdk-ng/tree/v0.13.2
- Z_SDKVER=0.13.2
- Z_SDKBIN=${HOME}/bin
- Z_INSTALL=${HOME}/zephyrproject


Install previous or other version:
- https://github.com/zephyrproject-rtos/sdk-ng/tree/v0.13.1
- Z_SDKVER=0.13.1
- This is for a brute force clean installation, not an upgrade.
- Delete files and run install script.


**Install Complete; move onto development.**

### Develop

#### Hardware
Any ESP32 board with the console serial port on the correct GPIO connected to USB should `hello_world` work.

#### Select a build environment, esp32, esp32s2, esp32c3
Use one *activate* script to develop for a specific ESP32 SOC. Each script sets up a Zephyr Python virtual environment and adds the correct Espressif tools to the PATH. This terminal session now can be used to develop with Zephyr for a supported ESP32 SOC.

Source only one script that matches the SOC name!

```
PICK ONLY ONE:

$ source z_esp32c3.sh
Now developing for esp32c3 SOC

-OR-
$ source z_esp32s2.sh
Now developing for esp32s2 SOC

-OR-
$ source z_esp32.sh
Now developing for esp32 SOC

(.venv) $
```

The Linux `PS1` terminal prompt changes to indicate in a Python virtual environment with a `(.venv)` prefix. To exit use Python venv keyword command `deactivate` to end virtual environment. The Linux `PS1` terminal prompt will now be without `(.venv)` prefix.
```
(.venv)$ deactivate
$
```

After `deactivate` you can run another `activate` script to select another ESP32 SOC.
Caution: the same `build` directory will be used and over-written.



#### Initial build
Open a terminal window. This is your development terminal.
1. Activate build environment.  `source z_esp32.sh` Terminal prompt changes: `(.venv) $`
2. Find and enter Zephyr sample directory. `cd hello_world`
3. Configure and set board only. No *zephyr.elf* built.  `west build --target guiconfig --board esp32`
4. ... Exit `guiconfig` window, no changes needed.
5. Build *zephyr.elf* - on disk. `west build`
6. Flash *zephyr.bin* - to board then reset. `west flash`
7. Reset board and monitor console `west espressif monitor`
8. ... Exit monitor with `CTRL+]` (simultaneous CTRL and RIGHT BRACKET)
9. Stay in development environment. And continue build/flash cycle.

The first `west build`, a *config-only-build* sets ARCH (ESP32 SOC), BOARD and launches a Kconfig option menu. There is no compile. No final `zephyr.elf` file is produced. Build meta-data are generated. Kconfig, CMake, Ninja and other *tool* errors are found.

For `hello_world`, accept all the default Kconfig settings by exiting the `guiconfig` pop-up GUI menu. Or use `--target menuconfig` for *ncurses* menu in current terminal window, \<ESC\> to exit. Do not close containing development terminal window!


The second `west build`, a real *build* creates a  `zephyr.elf` file then flashes `zephyr.bin` to board for the first time.  Board will reset and execute from flash. Optionally monitor board serial output. Will most likely work without `/dev/ttyUSB0` options since it is a common default under Linux.

After changing ARCH (ESP32 SOC) or BOARD `--pristine always` for a clean build. Second build `--pristine auto` clean as needed.

These are the exact commands for your copy-paste. Do not copy prompts.

- Shown: is: `source esp32.sh`,   board is generic `esp32`.
- Change to `source esp32s2.sh`, board to `esp32s2_saola`.
- Change to `source esp32c3.sh`, board to `esp32c3_devkitm`.

> Linux prompt `$` And Zephyr development prompt `(.venv) $`


```
$
$ source z_esp32.sh
Now developing for esp32 SOC
(.venv) $
(.venv) $ cd ~/zephyrproject/zephyr/samples/hello_world/
(.venv) $ west build --pristine always --target guiconfig --board esp32
(.venv) $
(.venv) $ west build --pristine auto
(.venv) $ west flash --esp-device /dev/ttyUSB0
(.venv) $ west espressif -p /dev/ttyUSB0 monitor
(.venv) $
```

#### Repeat build
Still in development environment from above `source z_esp32.sh` session. Prompt is still `(venv) $`.

1. Make code changes. 'atom' is a good code editor with integrated `git` tools.
2. And/or change `Kconfig` options `west build --target guiconfig`.
3. Build *zephyr.elf* - on disk. `west build`. This overwrites file on disk.
4. Flash *zephyr.bin* - to board. `west flash`. This overwrites image on board. Resets.
5. Optioanal reset board and monitor console `west espressif monitor` Exit with `CTRL+]`
6. ... Repeat

```
(.venv) $
(.venv) $ atom src/main.c
(.venv) $ west build --target guiconfig
(.venv) $
(.venv) $ west build --pristine auto
(.venv) $ west flash --esp-device /dev/ttyUSB0
(.venv) $
(.venv) $ west espressif -p /dev/ttyUSB0 monitor
(.venv) $
```

Repeat until all done!

#### Leave build environment

```
(.venv) $ deactivate
$
```


### Zephyr Installation File Structure
You can learn much, you can, from a good tree display.

Suprise! There is a ESP32 wifi example hiding, found while exploring. It works on an `esp32` board should work on `esp32s2_saola` board.
```
cd ~/zephyrproject/zephyr/samples/boards/esp32/wifi_station

Set WiFi credentials in `prj.conf`. Config Build Flash Monitor.

```


```
$HOME/zephyrproject    [location set with Z_INSTALL ]
├── bootloader/mcuboot/boot/
│       └──espressif
│          ├── bootloader.conf
│          ├── hal/include
│              ├── esp32
│              ├── esp32c3
│              ├── esp32s2
│                   ├── esp32s2.cmake
|                   └── sdkconfig.h    
|
├── modules
├── tools
└── zephyr
    ├── Kconfig
    ├── Kconfig.zephyr
    │
    ├── board         [supported espressif boards ]
    │   ├── riscv
    │   │   │── esp32c3_devkitm  [Espressif DEV BRD ]
    │   │   └── qemu_riscv32     [simulator unknown, untested ]   
    │   └── xtensa
    │       │── esp32           [Espressif ESP32 generic? ]
    │       │── esp32s2_saola   [Espressif ESP32S2-SAOLA DEV BRD - tested]
    │       └── qemu_xtensa     [simulator unknown, untested ]
    │
    └── samples
        ├── boards
        │   ├── esp32
        │       ├── spiram_test/
        │       └── wifi_station [suprise sample found from directory exploring ]
        │           ├── build           [exists only after first config-build]
        │           ├── boards
        │           │   └── esp32s2_saola.conf
        │           ├── src/
        │           ├── CMakeLists.txt
        │           ├── prj.conf    [CONFIG_* WIFI credentials for your network ]
        │           └── sample.yaml [ sets allowed BOARD esp32 or esp32s2_saola]
        │   
        └── hello_world         [this sample compiled here in Zephyr tree and flashed test program ]
            ├── build           [only after first config-build]
            │   └── zephyr
            │       ├── .config     [after menuconfig - holds all settings ]
            │       ├── zephyr.bin    [flash binary image  ]
            │       └── zephyr.elf    [after compile build final file  ]
            │
            └── prj.conf        [CONFIG_* entries for this applicaion - no example, it's empty ]

```

```
$HOME/bin
├── zephyr-sdk-0.13.2    [location set with Z_SDKBIN ]
│
├── z_esp32c3.sh         [activate venv, default location ]
├── z_esp32s2.sh         [activate venv, default location ]
└── z_esp32.sh           [activate venv, default location ]
```

```
$HOME/.espressif    [default location ]
├── dist
└── tools
    └── zephyr
        ├── openocd-esp32
        ├── riscv32-esp-elf     [supported SOC esp32c3 ]
        ├── xtensa-esp32-elf    [supported SOC esp32 ]
        └── xtensa-esp32s2-elf  [supported SOC esp32s2 ]

```

Assumes `${HOME}/bin` and `${HOME}/.local/bin` exist and are set in PATH.


 ## Find more Info
 #### Use west help files
 ```
 (.venv) $ west --help espressif

 usage: west espressif [-h] [-b BAUD] [-p PORT] [-e ELF] {install,update,monitor}

 This interface allows updating hal_espressif submodules, installing Espressif toolchain and open serial monitor for Espressif SoC
 devices.

 positional arguments:
   {install,update,monitor}
                         install espressif toolchain or fetch submodules

 optional arguments:
   -h, --help            show this help message and exit

 monitor optional arguments:
   -b BAUD, --baud BAUD  Serial port baud rate
   -p PORT, --port PORT  Serial port address
   -e ELF, --elf ELF     ELF file
 ```

 Show valid --target arguments.
 ```
 (.venv) $ west build --target usage

 -- west build: running target usage
 Cleaning targets:
   clean     - Remove most generated files but keep configuration and backup files
   pristine  - Remove all files in the build directory

 Kconfig targets:
   menuconfig - Update .config using a console-based interface
   guiconfig  - Update .config using a graphical interface

 Other generic targets:
   all          - Build a zephyr application
   run          - Build a zephyr application and run it if the board supports emulation
   flash        - Run "west flash"
   debug        - Run "west debug"
   debugserver  - Run "west debugserver" (or start GDB server on port 1234 for QEMU targets)
   attach       - Run "west attach"
   ram_report   - Build and create RAM usage report
   rom_report   - Build and create ROM usage report
   boards       - Display supported boards
   shields      - Display supported shields
   usage        - Display this text
   help         - Display all build system targets

 Build flags:

   ninja -v [targets] verbose build
   cmake -DW=n   Enable extra gcc checks, n=1,2,3 where
    1: warnings which may be relevant and do not occur too often
    2: warnings which occur quite often but may still be relevant
    3: more obscure warnings, can most likely be ignored
    Multiple levels can be combined with W=12 or W=123

 ```

### SPDX
SPDX-License-Identifier: Apache-2.0

SPDX-FileCopyrightText: 2021 Robert Connaghan (burtrum)

#### EOF
