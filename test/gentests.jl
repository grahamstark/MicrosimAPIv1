
@testset "basic db" begin
    #Random.seed!(1234);
    conn = makeconn()
    @test ! isnothing(conn)
    @show conn
    LibPQ.close(conn)
    clear_expired_temp_users()
end

@testset "Utils" begin
    s2 = deepcopy( DEFAULT_MINI_PARAMS[:SimpleParams])
    @test structname( s2 ) == "SimpleParams"
    @show tohtml( DataFrame())
    @show struct_to_labels( s2 )
    @test length( tvalidate( s2 )) == 0
    s2.taxrates[2] = 120 # max is 100
    s2.taxbands[3] = -9 # min is zero
    errs = tvalidate( s2 )
    @show errs
    @test length( errs ) == 2
end

@testset "Model Run" begin
    global uid
    clear_expired_temp_users()
    edition = "simple-2026a"
    subsys = :SimpleParams
    user, run = handle_middle( uid, "scotben", edition, nothing )
    change_run_state!( run; qstatus='Q', output_is_cached=false )
    minip = deepcopy( DEFAULT_MINI_PARAMS[subsys] )
    minip.taxrates[2]=25
    errs = tvalidate( minip )
    save_params( run, subsys, minip, errs)
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
    uid = user.user_id
    load_output!( run )
    @test run.output_is_cached
    change_run_state!( run; qstatus='C', output_is_cached=true )
end
