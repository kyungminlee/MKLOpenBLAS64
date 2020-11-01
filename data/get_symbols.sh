#nm -D /usr/lib/x86_64-linux-gnu/libmkl_core.so | grep " T " | awk '{ print $3; }' > list_core
#nm -D /usr/lib/x86_64-linux-gnu/libmkl_sequential.so | grep " T " | awk '{ print $3; }' > list_sequential
nm -D /usr/lib/x86_64-linux-gnu/libmkl_intel_ilp64.so | grep " T " | awk '{ print $3; }' > list_ilp64
nm -D ~/.local/pkg/julia-1.5.2/lib/julia/libopenblas64_.so | grep " T " | awk '{ print $3; }' > list_openblas64
