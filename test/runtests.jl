
#=
Not explicitly using the package is a bit unconventional, but, as Claude paints out,
including the files directly is the only way we can invoke
the Oxygen macros in test cases without actually starting a server.
=#

using Test



include( "../src/loadall.jl")

# this global user id means we can share a temp user between all the tests from the 1st time one is created
clear_all_temp_users()
uid = -123

include("gentests.jl")
include( "dbtests.jl")
include( "apitests.jl")
