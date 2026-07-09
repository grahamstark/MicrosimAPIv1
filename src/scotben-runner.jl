function grab_runs_from_queue(i::Integer)
    while true
        run = next_runnable_run()
        if ! isnothing( run )
            @info "run $(run.run_id) for user $(run.user_id) started in handler $(i)"
            h = make_param_hash( run.user_id, run.model_name, run.model_edition, run.run_id )
            if ! output_is_cached( run, h )
                change_run_state!( run; qstatus='E', output_is_cached=false )
                allout = do_run(
                    run.user_id,
                    run.model_name,
                    run.model_edition,
                    run.run_id,
                    minip,
                    update_progress=update_progress, do_dumps=true  )
                cache_output( run, h, allout )
            end
            load_output!( run )
            change_run_state!( run; qstatus='C', output_is_cached=true )
        else
            @debug "no runnable runs for handler $(i)"
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
    for i in 1:num_handlers # start n tasks to process requests in parallel
        @info "starting handler $i"
        # took errormonitor off on Claude's advice.
        push!( tasks, @async grab_runs_from_queue(i))
    end
    return tasks
end

#=
function start_scotben_queues(num_handlers=3)
    tasks = []
    for i in 1:num_handlers # start n tasks to process requests in parallel
        @info "starting handler $i"
        push!(tasks, @task grab_runs_from_queue())
    end
    return tasks
end
=#
