# Homework 1 - Linux Kernel Update

## Task

Update Linux kernel on VM using package from mainline repository.

**Extra task**: Build kernel from sources and then update.

## Prerequisites

Host OS: **Windows 11 24H2**

Guest OS: **Ubuntu Server 24.04**

## Solution

### 1. Installing OS on VM and connecting via SSH

*no comments*

### 2. Checking kernel version and architecture

```console
root@ubuntu:~# uname -r
6.8.0-106-generic

root@ubuntu:~# uname -p
x86_64
```

### 3. Find available kernel versions in mainline repository

![kernel versions](img/kernel_versions.png)

Choosing `6.13.2` (and `6.13.4` for later)

### 4. Download amd64 packages

```console
root@ubuntu:~# mkdir kernel
root@ubuntu:~# cd kernel/
```

```console
root@ubuntu:~/kernel# wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.2-061302_6.13.2-061302.202502081010_all.deb https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-image-unsigned-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-modules-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb
```

### 5. Install packages and validate installation

```console
root@ubuntu:~/kernel# sudo dpkg -i *.deb

root@ubuntu:~/kernel# ls -la /boot/ | grep vm
lrwxrwxrwx  1 root root       29 Mar 31 19:42 vmlinuz -> vmlinuz-6.13.2-061302-generic
-rw-------  1 root root 15647232 Feb  8  2025 vmlinuz-6.13.2-061302-generic
-rw-------  1 root root 15034760 Mar  6 06:23 vmlinuz-6.8.0-106-generic
lrwxrwxrwx  1 root root       25 Mar 31 18:22 vmlinuz.old -> vmlinuz-6.8.0-106-generic
```

### 6. Update grub to use new kernel by default and reboot VM

```console
root@ubuntu:~/kernel# sudo update-grub
root@ubuntu:~/kernel# sudo grub-set-default 0
root@ubuntu:~/kernel# reboot
```

### 7. Validate new version of kernel is being used

```console
root@ubuntu:~# uname -r
6.13.2-061302-generic
```

## Extra: Building kernel from sources

### 1. Install build dependencies

```console
sudo apt update
sudo apt install -y build-essential fakeroot libncurses-dev libssl-dev bison \ 
    flex libelf-dev dwarves git bc rsync debhelper
```

### 2. Download and unpack Linux kernel 6.13.4 source code

```console
root@ubuntu:~/kernel-build# wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.13.4.tar.xz

root@ubuntu:~/kernel-build# ls
linux-6.13.4.tar.xz

root@ubuntu:~/kernel-build# tar -xf linux-6.13.4.tar.xz

root@ubuntu:~/kernel-build# ls
linux-6.13.4  linux-6.13.4.tar.xz

root@ubuntu:~/kernel-build# cd linux-6.13.4/
```

### 3. Configure installation based on default settings

```console
root@ubuntu:~/kernel-build/linux-6.13.4# make mrproper

root@ubuntu:~/kernel-build/linux-6.13.4# make defconfig
  HOSTCC  scripts/basic/fixdep
  HOSTCC  scripts/kconfig/conf.o
  HOSTCC  scripts/kconfig/confdata.o
  HOSTCC  scripts/kconfig/expr.o
  LEX     scripts/kconfig/lexer.lex.c
  YACC    scripts/kconfig/parser.tab.[ch]
  HOSTCC  scripts/kconfig/lexer.lex.o
  HOSTCC  scripts/kconfig/menu.o
  HOSTCC  scripts/kconfig/parser.tab.o
  HOSTCC  scripts/kconfig/preprocess.o
  HOSTCC  scripts/kconfig/symbol.o
  HOSTCC  scripts/kconfig/util.o
  HOSTLD  scripts/kconfig/conf
*** Default configuration is based on 'x86_64_defconfig'
#
# configuration written to .config
#
```

### 4. Build binary .deb packages (with custom name)

```console
root@ubuntu:~/kernel-build/linux-6.13.4# make -j$(nproc) bindeb-pkg LOCALVERSION=-custom-6.13.4
```

Files were built in parent directory:

```console
root@ubuntu:~/kernel-build/linux-6.13.4# cd ../
root@ubuntu:~/kernel-build# ls -la *.deb
-rw-r--r-- 1 root root  9121170 Mar 31 21:24 linux-headers-6.13.4-custom-6.13.4_6.13.4-2_amd64.deb
-rw-r--r-- 1 root root 14412974 Mar 31 21:24 linux-image-6.13.4-custom-6.13.4_6.13.4-2_amd64.deb
-rw-r--r-- 1 root root  1450688 Mar 31 21:23 linux-libc-dev_6.13.4-2_amd64.deb
```

### 5. Install built .deb packages

```console
root@ubuntu:~/kernel-build# sudo dpkg -i *.deb

root@ubuntu:~/kernel-build# ls -la /boot | grep vm
lrwxrwxrwx  1 root root       29 Mar 31 19:42 vmlinuz -> vmlinuz-6.13.2-061302-generic
-rw-------  1 root root 15647232 Feb  8  2025 vmlinuz-6.13.2-061302-generic
-rw-r--r--  1 root root 13546496 Mar 31 21:15 vmlinuz-6.13.4-custom-6.13.4
-rw-------  1 root root 15034760 Mar  6 06:23 vmlinuz-6.8.0-106-generic
lrwxrwxrwx  1 root root       25 Mar 31 18:22 vmlinuz.old -> vmlinuz-6.8.0-106-generic
```

### 6. Verify installation after rebooting VM

```console
root@ubuntu:~/kernel-build# sudo update-grub
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.13.4-custom-6.13.4
Found initrd image: /boot/initrd.img-6.13.4-custom-6.13.4
Found linux image: /boot/vmlinuz-6.13.2-061302-generic
Found initrd image: /boot/initrd.img-6.13.2-061302-generic
Found linux image: /boot/vmlinuz-6.8.0-106-generic
Found initrd image: /boot/initrd.img-6.8.0-106-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

root@ubuntu:~/kernel-build# sudo grub-set-default 0

root@ubuntu:~/kernel-build# reboot

root@ubuntu:~# uname -r
6.13.4-custom-6.13.4
```
