#include "mklopenblas64.h"
#include <stdio.h>

API_EXPORT
char *
openblas_get_config64_() {
    static char buf[128];
    snprintf(buf, 128, "OpenBLAS mkl_replacement USE64BITINT NO_AFFINITY USE_OPENMP Unknown MAX_THREADS=%d", mkl_get_max_threads());
    return buf;
}

API_EXPORT
char *
openblas_get_corename64_() {
    return "Unknown";
}

API_EXPORT
int
openblas_get_num_procs64_() {
    return mkl_get_max_threads(); // currently not well supported
}

API_EXPORT
int
openblas_get_num_procs_64_() {
    return mkl_get_max_threads();
}

API_EXPORT
int
openblas_get_num_threads64_() {
    return mkl_get_max_threads();
}

API_EXPORT
int
openblas_get_num_threads_64_() {
    return mkl_get_max_threads();
}

int
API_EXPORT
openblas_get_parallel64_() {
    return 2; // 0: sequential, 1: pthread, 2: openmp
}

API_EXPORT
int
openblas_get_parallel_64_() {
    return 2; // 0: sequential, 1: pthread, 2: openmp
}

API_EXPORT
void
openblas_set_num_threads64_(int nt) {
    mkl_set_num_threads(nt);
}

API_EXPORT
void
openblas_set_num_threads_64_(int nt) {
    mkl_set_num_threads(nt);
}

API_EXPORT
void
goto_set_num_threads64_(int nt) {
    mkl_set_num_threads(nt);
}

API_EXPORT
MKL_Complex16
lapack_make_complex_double64_( double re, double im ) {
    MKL_Complex16 z = {re, im};
    return z;
}

API_EXPORT
MKL_Complex8
lapack_make_complex_float64_( float re, float im ) {
    MKL_Complex8 z = {re, im};
    return z;
}


