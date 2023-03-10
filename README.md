# UEFI Bare Bones
A minimal "Hello World" kernel.

## Prerequisites

* git, wget, meson, the text editor of your choice, …
* clang with lld-link

## Building

Set up a build directory. Run `meson setup --cross-file uefi.cross-file <your build directory>`. In the build directory, run `ninja`.

Example:

```sh
mkdir -p build
meson setup --cross-file=uefi.cross-file build
cd build
ninja
```

## Running

Make sure you have a `OVMF.fd` ready. If you have a OVMF package installed, it can usually be copied from a path like `/usr/share/ovmf/x64/`.

Set up an ESP in the build directory like this:

```sh
cp /usr/share/ovmf/x64/OVMF.fd .
mkdir -p esp/EFI/BOOT/
cp BOOTX64.EFI esp/EFI/BOOT
```

After this, you can run QEMU. A recommended setup looks like this:

```sh
qemu-system-x86_64 -drive if=pflash,format=raw,file=OVMF.fd -M accel=kvm:tcg -net none -serial stdio -drive format=raw,file=fat:rw:esp
```
