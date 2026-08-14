module MicrosimAPIv1

include( "uses.jl")
include( "utils.jl")
include( "examples.jl")
include( "scotben-functions.jl")
include( "db-functions-and-consts.jl")
include( "microsim-api-oxygen.jl")
include( "scotben-runner.jl")
include( "initialisation-functions.jl")

const TEST_PORT = 8999
const LIVE_PORT = 9091

export doserve, testserve


function create_logger( postfix :: String )
    datestring = Dates.format(now(), "dd-u-YYYY")
    io = open( joinpath( homedir(), "api-logging", "MicrosimAPI-$(datestring)-$(postfix).log"), "w+")
    base_logger = SimpleLogger(io, Logging.Info ) # or Debug, Warn, Error
    logger = FlushingLogger(base_logger, io)
    global_logger(logger)
end

function doserve()
    create_logger( "server-live")
    serve(; middleware=[CorsMiddleware], port=LIVE_PORT)
end

function testserve()
    create_logger( "server-dev")
    serve(; middleware=[CorsMiddleware], port=TEST_PORT, revise=:eager)
end

end # module
