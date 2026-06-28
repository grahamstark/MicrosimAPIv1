
function grab_runs_from_queue(i::Integer)
    while true
        run = next_runnable_run()
        if ! isnothing( run )
            @info "run $(run.run_id) for user $(run.user_id) started in handler $(i)"

        end
    end
end

const NUM_HANDLERS = 3 #

#
# Run the job queues
#
function start_scotben_queue(num_handlers=NUM_HANDLERS)
    for i in 1:num_handlers # start n tasks to process requests in parallel
        @info "starting handler $i"
        errormonitor( @async grab_runs_from_queue(i))
    end
end
