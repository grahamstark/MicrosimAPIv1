
#=
Not explicitly using the package is a bit unconventional, but, as Claude paints out,
including the files directly is the only way we can invoke
the Oxygen macros in test cases without actually starting a server.
=#

using Test

include( "../src/loadall.jl")
# nclude("gentests.jl")
include( "apitests.jl")
