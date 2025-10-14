module MicrosimAPIv1

using Genie
using GenieSession 
using Genie.Requests
using GenieSessionFileSession
import Genie.Renderer.Json: json
using Jedis

using DataFrames
using DataStructures
using HTTP
using JSON3
using Markdown 
using LoggingExtras
using Observables
using Parameters
using StructTypes
using SwaggerMarkdown
using SwagUI
using UUIDs

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .LocalLevelCalculations
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils

include( "examples.jl")
include( "scotben-api-constants.jl")
include( "scotben-api-impl.jl")


const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

function __init__()
    global t
    t = @async calc_one()
    for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
        @info "starting handler $i" 
        errormonitor(t)
    end
end

#=
    to start from repl: 
    ENV["GENIE_ENV"]="dev" # or "windows" # or "prod" or "dev" or "debug"
    using Genie
    using MicrosimAPIv1
    Genie.loadapp()
    up()
=#

end
