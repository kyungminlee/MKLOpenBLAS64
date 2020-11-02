
using BenchmarkTools
using LinearAlgebra
using Random
rng = MersenneTwister(0)
m = rand(rng, ComplexF64, 2048, 2048)
m = Hermitian(m + m')
display(@benchmark eigen(m))
println()
@show eigen(m).values[1]
