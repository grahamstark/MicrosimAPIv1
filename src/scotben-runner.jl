# dear old Claude put me right about ReentrantLock vs SpinLock
qlock = ReentrantLock()
# .. or SpinLock()

"""

Create a queue of num_handlers tasks which listen for any jobs in 'Q' state and runs them.
See `bin/runner-listener.jl` and `etc/runner-listener.service` for invoking this.

FIXME This is a very basic version that assumes a single param set, either UBI or SimpleParams. We need a bigger version with
all parameters.,

"""
function grab_runs_from_queue(handler_number::Integer)
    # global qlock
    while true
        # fixme use a transaction??
        # @lock stops multiple workers grabbing the same job
        run = nothing
        lock(qlock) do
            run = next_runnable_run()
            @info "run = " run
        end
        if ! isnothing( run )
            @info "run $(run.run_id) for user $(run.user_id) started in handler $(handler_number)"
            h = make_param_hash( run.user_id, run.model_name, run.model_edition, run.run_id )
            if ! output_is_cached( run, h )
                change_run_qstate!( run; qstatus='X', output_is_cached=false )
                para1 = collect(values(run.params))[1] # FIXME 1st set pf parameters only
                allout = do_run(
                    run.user_id,
                    run.model_name,
                    run.model_edition,
                    run.run_id,
                    para1;
                    update_progress=update_progress,
                    do_dumps=true  )
                cache_output( run, h, allout )
            end
            load_output!( run )
            set_run_to_displayed!( run )
            clearup_run_states( run, 0 )
        else
            @debug "no runnable runs for handler $(handler_number)"
            sleep(1)
        end
    end
end

"""
 create a vector of num_handlers job queue handlers
 see bin/run-listener.jl|sh for how to use the queue
"""
function create_scotben_queues(num_handlers=3)
    tasks = Task[]
    for handler_number in 1:num_handlers # start n tasks to process requests in parallel
        @info "starting handler $handler_number"
        # push!( tasks, @async grab_runs_from_queue(handler_number))
        # spawn (seperate tasks) causes Makie error:  nested task error: ConcurrencyViolationError("Vector can not be resized concurrently")

        push!( tasks, Threads.@spawn grab_runs_from_queue(handler_number))
    end
    return tasks
end
