module MicrosimAPIv1

using Genie

# using GenieSession 
using Genie.Requests
# using GenieSessionFileSession
import Genie.Renderer.Json: json
using Jedis


include( "ScotbenAPIImpl.jl")
include( )
export ScotbenAPIImpl

const up = Genie.up
export up

function main()
    Genie.genie(; context = @__MODULE__)
end

function __init__()
    global t
    t = @async ScotbenAPIImpl.calc_one()
    for i in 1:ScotbenAPIImpl.NUM_HANDLERS # start n tasks to process requests in parallel
        @info "starting handler $i" 
        ScotbenAPIImpl.errormonitor(t)
    end
end

end
