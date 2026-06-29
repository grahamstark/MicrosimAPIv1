function grab_runs_from_queue(i::Integer)
    while true
        # FIXME can we simplify this
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
            # FIXME add a version that doesn't change output_is_cached
            # FIXME we don't actually ever need to load the output into the run record?
            change_run_state!( run; qstatus='C', output_is_cached=true )
        else
            @info "no runnable runs for handler $(i)"
            sleep(1)
        end
    end
end

const NUM_HANDLERS = 3 #

#
# Run the job queues
#
function start_scotben_queues(num_handlers=NUM_HANDLERS)
    for i in 1:num_handlers # start n tasks to process requests in parallel
        @info "starting handler $i"
        errormonitor( @async grab_runs_from_queue(i))
    end
end
