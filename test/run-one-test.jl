user, run = msa.handle_middle(nothing,"scotben", "simple-2026a")
run.params[:SimpleParams].uc_taper = rand(1.0:0.10:100)
msa.save_run( run )
submission = msa.submit_run( run.user_id, run.model_name, run.model_edition )
r_run = msa.next_runnable_run()
i = 1
if ! isnothing( r_run )
    msa.change_run_qstate!( r_run; qstatus='L', output_is_cached=r_run.output_is_cached )
    @info "run $(r_run.run_id) for user $(r_run.user_id) started in handler $(i)"
    h = msa.make_param_hash( r_run.user_id, r_run.model_name, r_run.model_edition, r_run.run_id )
    if ! msa.output_is_cached( run, h )
        msa.change_run_qstate!( r_run; qstatus='X', output_is_cached=false )
        para1 = collect(values(run.params))[1]
        allout = msa.do_run(
            r_run.user_id,
            r_run.model_name,
            r_run.model_edition,
            r_run.run_id,
            para1,
            update_progress=msa.update_progress, do_dumps=true  )
        msa.cache_output( r_run, h, allout )
    end
    msa.load_output!( r_run )
    msa.change_run_qstate!( r_run; qstatus='C', output_is_cached=true )
    msa.clearup_run_states( r_run, 0 )
else
    @debug "no runnable runs for handler $(i)"
    sleep(1)
end
