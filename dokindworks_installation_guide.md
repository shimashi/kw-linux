
# dokindworks.org - Automated Debian Cinnamon Installation Guide

## 1. Introduction

Welcome to dokindworks.org! This guide will walk you through the installation of a customized Debian operating system with the Cinnamon desktop environment. The installation is fully automated, so you can sit back and relax while the system is being set up for you.

This special version of Debian is designed to be easy to use and comes with a curated selection of software to get you started.

## 2. Prerequisites

Before you begin, you will need:

*   A USB drive with at least 4GB of storage. **All data on this drive will be erased.**
*   The `debian-cinnamon-autoinstall-v2.iso` file you created.
*   An internet connection for the post-installation steps.

## 3. Creating the Bootable USB Drive

You need to write the downloaded ISO file to a USB drive to make it bootable. Follow the instructions for your operating system.

### For Linux

You can use the `dd` command to write the ISO to your USB drive.

1.  **Find your USB drive's device name.** You can use the `lsblk` command to list your storage devices. Look for a device that matches the size of your USB drive (e.g., `/dev/sdX`).
2.  **Unmount the USB drive** if it's mounted automatically. Replace `/dev/sdXn` with the partitions on your USB drive (e.g., `/dev/sdb1`).
    ```bash
    sudo umount /dev/sdXn
    ```
3.  **Write the ISO to the USB drive.** Replace `debian-cinnamon-autoinstall-v2.iso` with the path to your ISO file and `/dev/sdX` with your USB drive's device name.
    ```bash
    sudo dd if=debian-cinnamon-autoinstall-v2.iso of=/dev/sdX bs=4M status=progress oflag=sync
    ```

### For Windows

For Windows, we recommend using a free tool like [Rufus](https://rufus.ie/) or [Balena Etcher](https://www.balena.io/etcher/).

1.  Download and install your chosen tool.
2.  Open the application.
3.  Select the `debian-cinnamon-autoinstall-v2.iso` file.
4.  Select your USB drive.
5.  Click the "Flash" or "Start" button to begin the process.

### For macOS

For macOS, you can use [Balena Etcher](https://www.balena.io/etcher/) or the `dd` command.

1.  Download and install Balena Etcher, or open a Terminal for the `dd` command.
2.  **Using Balena Etcher:** The process is the same as on Windows. Select the ISO, select the USB drive, and flash it.
3.  **Using the `dd` command:**
    1.  Find your USB drive's device name with `diskutil list`.
    2.  Unmount the drive with `diskutil unmountDisk /dev/diskX`.
    3.  Write the ISO with:
        ```bash
        sudo dd if=/path/to/debian-cinnamon-autoinstall-v2.iso of=/dev/rdiskX bs=4m
        ```
        (Using `/dev/rdiskX` is faster than `/dev/diskX`).

## 4. Booting from the USB Drive

1.  Insert the bootable USB drive into the computer where you want to install Debian.
2.  Restart or turn on the computer.
3.  As the computer starts up, press the key to open the boot menu. This key is usually **F2, F10, F12, or DEL**. It depends on your computer's manufacturer.
4.  From the boot menu, select your USB drive.

## 5. The Automated Installation

Once you boot from the USB drive, the installation will start automatically. You won't need to do anything. The installer will partition the hard drive, install the base system, and set up the Cinnamon desktop environment.

The computer will restart automatically when the installation is complete. **Remove the USB drive when the computer restarts.**

## 6. Post-Installation Steps

After the installation, you'll have a fully functional Debian system with the Cinnamon desktop. To complete the setup and install additional applications, you need to run a script.

1.  Boot into your new Debian system.
2.  Connect to the internet.
3.  Open a **Terminal**. You can find it in your applications menu.
4.  **Clone the `kw-linux` repository** by running the following command:
    ```bash
    git clone https://github.com/LenovoGuy98/kw-linux.git
    ```
5.  **Navigate into the cloned directory:**
    ```bash
    cd kw-linux
    ```
6.  **Run the `install_apps.sh` script:**
    ```bash
    bash install_apps.sh
    ```

This script will install a selection of useful applications, including Audacity, Firefox, LibreOffice, Zoom, and Google Chrome.

Verify Audio and Video work!


## 7. Congratulations!

You have successfully installed and configured your new dokindworks.org Debian system. Enjoy!
