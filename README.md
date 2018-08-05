# UEFI Bare Bones
A minimal "Hello World" kernel.

# Prerequisites
* git, wget, make, the text editor of your choice, …
* [jiri](https://github.com/fuchsia-mirror/jiri)
* clang with lld-link-6.0 or binutils + gcc with the x86_64-w64-mingw32 target (on Ubuntu run `apt install clang lld-6.0` or `apt install mingw-w64-x86-64-dev`)
* mtools (for building FAT32 images): `apt install mtools`
* xorriso (for building CDs, depends on mtools): `apt install xorriso`

# Building
Make sure [jiri](https://github.com/fuchsia-mirror/jiri) is installed. Running `make prepare` will set up the environment by running `jiri update`, which will pull the zircon UEFI headers into `kernel/include/efi`.

Running `make kernel` (or alternatively simply `make`) will build the kernel. Testing in QEMU is set up and run by `make test`.

## Build options
* setting USE_GCC=1 switches the compiler from clang to gcc
* setting MODE=fat builds a FAT32 disk image, MODE=cd creates a CD `.iso`, while passing MODE=dir (which it defaults to) puts everything in bin/hdd
