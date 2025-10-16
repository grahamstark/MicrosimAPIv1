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
using Random
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
    # Genie.Configuration.config!(; server_handle_static_files = true )
    # Genie.Configuration.config!(; server_document_root = "/home/graham_s/julia/vw/MicrosimAPIv1/web/" )
    # Genie.Configuration.config!(; cors_allowed_origins = ["*"])
    # Genie.Configuration.add_cors_header!("Access-Control-Allow-Origin", "*")
    # Genie.Configuration.config!("Access-Control-Allow-Origin", "*")
     Genie.genie(; context = @__MODULE__)
end

function get_session_id()
    id = payload(:session_id,"Missing")
    if id == "Missing"
        id = randstring(60)
    end
    return id;
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
Genie.config.cors_allowed_origins=["*"]
Genie.config.cors_headers["Access-Control-Allow-Credentials"]="true"
Genie.config.cors_headers["Access-Control-Allow-Headers"]="*"
=# 

#=
    to start from repl: 
    ENV["GENIE_ENV"]="dev" # or "windows" # or "prod" or "dev" or "debug"
    using Genie
    using MicrosimAPIv1
    Genie.loadapp()
    up()
=#

end
