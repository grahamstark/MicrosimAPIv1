module ScotbenAPIImpl

using Genie

# using GenieSession
using Genie.Requests
# using GenieSessionFileSession
import Genie.Renderer.Json: json
using Jedis

include( "uses.jl")
include( "examples.jl")

include( "db-functions-and-consts.jl")
include( "scotben-functions.jl")
include( "genie-functions.jl")
include( "scotben-api-impl.jl")

#
# Foolish decision to index runs by UUIDs...
#
const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")
const DEF_PROGRESS = Progress( BASE_UUID, "na", 0, 0, 0, 0 )


#
# 3 data structures
# - SESSION - Dict of user data, keyed by session_id
# - CACHED_RESULTS - Dict, keyed by hash of parameters
# - JOB_QUEUE - Channel of
#
const QSIZE = 32
const SESSIONS = Dict{String, ParamsAndSettings}()
const CACHED_RESULTS = Dict{UInt, AllOutput}()
# const DEFAULT_SETTINGS = make_default_settings()

JOB_QUEUE = Channel{ParamsAndSettings}(QSIZE)

#
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 8

function calc_one()
	while true
		@info "calc_one entered"
		prs = take!( JOB_QUEUE )
        @info "params taken from JOB_QUEUE; got params"
		do_run( prs )
		@info "model run OK; putting results into CACHED_RESULTS"		
	end
end

function __init__()
    # configure logger; see: https://docs.julialang.org/en/v1/stdlib/Logging/index.html
    # and: https://github.com/oxinabox/LoggingExtras.jl
    logdir = mktempdir()
    logger = FileLogger(joinpath( logdir, "microsim-api-log.txt"))
    @show logdir
    global_logger(logger)
    LogLevel( Logging.Debug )
    hid = do_default_run()
    @show "default hid" hid
end

end # module
