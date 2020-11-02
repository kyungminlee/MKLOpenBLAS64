# MKLOpenBLAS64

**USE AT YOUR OWN DISCRETION !!!**

Replace Julia's OpenBLAS64 with MKL ILP64, and speed up your Julia.

Binary builds of Julia use OpenBLAS for linear algebra operations.
On Intel processors, however, Intel's MKL has some black magic that give you surprising performance boost.

[MKL.jl](https://github.com/JuliaComputing/MKL.jl) replaces the Julia's linear algebra routines with MKL, and should work for most people.
A problem for some people is that it links to the 32-bit integer interface of MKL, due to compatibility issue with numpy's MKL from Conda.
If your matrices have dimensions larger than 46340, you have a problem.

MKLOpenBLAS64 is a simple wrapper around MKL ILP64, designed to be a simple replacement for Julia's OpenBLAS while maintaining its 64-bit integer interface.


## Installation

To build MKLOpenBLAS64, you must bring your own copy of *static* MKL libraries.
It is publicly available online for free, and has recently been added to Debian's `non-free` repository and Ubuntu 20.04 as well.

Create `options.cmake` which sets `MKL_INCLUDE_PATH` and `MKL_LIBRARIES`. Note that the library must contain `mkl_intel_ilp64`, `mkl_gnu_thread` (or `mkl_intel_thread` or `mkl_sequential` depending on your needs and operating system), and `mkl_core.a`.
(Consult [Intel® Math Kernel Library Link Line Advisor](https://software.intel.com/content/www/us/en/develop/articles/intel-mkl-link-line-advisor.html).
Make sure to select "64-bit integer" interface layer.)
Examples can be found in `options.cmake.win32` and `options.cmake.linux`.
When you want to generate `mklopenblas64.c` yourself, see [Advanced Installation](#advanced-installation)

```
$ cmake -B build
$ cmake --build build 
```
Now replace Julia's `libopenblas64_.so` (`.dylib` on macOS, `.dll` on Windows) with the generated `libmklopenblas64_.so`.
If you are on Windows using `mkl_intel_thread`, you should also copy `libiomp5.dll` to your Julia's `bin` directory.

## Advanced Installation

This part is not necessary for most people.

MKLOpenBLAS64 uses `mklopenblas64.c` generated from the mkl headers `mkl_blas.h`, `mkl_cblas.h`, `mkl_lapack.h`, and `mkl_lapacke.h` using Clang parser.
To generate `mklopenblas64.c`, you first want to extract out the exported symbols from `mkl_intel_ilp64`, and Julia's `openblas64`.
`data/get_symbols.sh` will generate `list_ilp64` and `list_openblas64` that contain the list of exported symbols from the two libraries.
(`list_openblas64` is already included in this repository.)
Change `data/get_symbols.sh` to match your system and run
```
$ cd data
$ ./get_symbols.sh
```
To build the generator for `mklopenblas64.c`, you must also checkout the `fmt` submodule
```
$ git submodule update --init
```
You also need `clang` to generate the parser.
Make sure you have it installed, and set the variables `CLANG_INCLUDE_PATH`, `CLANG_LIBRARIES` in `options.cmake`.
The `CLANG_INCLUDE_PATH` should point to a directory that contains a subdirectory `clang-c`.
Once you are done, you can delete the existing `mklopenblas64.c` and build as usual:
```
$ cmake -B build
$ cmake --build build 
```
