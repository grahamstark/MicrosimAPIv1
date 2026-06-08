module MicrosimAPIv1

include( "uses.jl")
include( "scotben-functions.jl")
include( "examples.jl")
include( "db-functions-and-consts.jl")

function __init__()


    global BASE_RESULTS = do_default_run()


    # global t
    # t = @async ScotbenAPIImpl.calc_one()
    # for i in 1:ScotbenAPIImpl.NUM_HANDLERS # start n tasks to process requests in parallel
    # @info "starting handler $i"
    # ScotbenAPIImpl.errormonitor(t)
    # end
end

end
