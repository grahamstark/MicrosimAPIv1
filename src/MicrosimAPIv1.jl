module MicrosimAPIv1

include( "uses.jl")
include( "utils.jl")
include( "examples.jl")
include( "scotben-functions.jl")
include( "db-functions-and-consts.jl")
include( "oxygen-functions.jl")

const TEST_PORT = 8999
const LIVE_PORT = 9090

export doserve, testserve

doserve() = serve(; middleware=[CorsMiddleware], port=LIVE_PORT)
testserve() = serve(; middleware=[CorsMiddleware], port=TEST_PORT, revise=:eager)

function __init__()

end

end # module
