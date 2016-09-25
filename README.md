C++ with Clang and libc++
=========================

This repository contains images designed for C++ build automation using Clang
and libc++. The images ship with complete Clang based toolchains including some
utilities for build system creation and dependency management. Different
versions of LLVM/Clang are available via their respective tags (e.g 3.6, 3.7,
3.8, etc.)

The images are designed with mainly Gitlab CI and TravisCI in mind, but can
also be use in a standalone manner. Note that you must explicitly specify a tag
when using any of these images, since there is no `latest` tag.

Included tools
--------------

| Tool     | Version          |
| -------- | ---------------- |
| Autoconf | 2.69             |
| Automake | 1.15             |
| Clang    | *depending on tag* |
| CMake    | 3.6.2            |
| Conan    | 0.12.0           |
| Make     | 2.4.1            |
| Ninja    | 1.7.1            |

