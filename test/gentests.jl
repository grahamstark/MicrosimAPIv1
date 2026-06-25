
@testset "basic db" begin
    #Random.seed!(1234);
    conn = makeconn()
    @test ! isnothing(conn)
    @show conn
    LibPQ.close(conn)
    clear_expired_temp_users()
end

@testset "Utils" begin
    s2 = deepcopy( DEFAULT_MINI_PARAMS["SimpleParams"])
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

@testset "DB Middleware" begin
    initialise_database()
    models = get_available_models()
    sys = deepcopy( DEFAULT_PARAMS )
    @test size(models)[1] >= 1 # at least 1 model
    for m in eachrow(models)
        editions = get_available_editions( m.model_name )
        @test size(editions)[1] >= 1 # at least 1 model
        for e in eachrow( editions )
            model = get_model( m.model_name, e.model_edition )
            @test model.name == m.model_name
            ss = get_available_subsystems( model.name, e.model_edition )
            @test size(ss)[1] >= 1 # at least 1 subsystem
            for s in eachrow(ss)
                minip=DEFAULT_MINI_PARAMS[s.subsys]
                @show minip
                map_simple_to_full!( sys, minip )
            end
        end
    end
    # middleware thing test
    uid = 123456
    user, run = handle_middle( uid, "scotben", "simple-2026a", nothing )
    @test user.user_id != uid
    @test run.user_id == user.user_id
    # try again - should persist this time
    user2, run2 = handle_middle( user.user_id, run.model_name, run.model_edition, nothing )
    # check we've brought back the same user and run this time
    @test user2.user_id == user.user_id
    @test run2.run_id == run.run_id
end

@testset "Model Run" begin
    clear_expired_temp_users()
    edition = "simple-2026a"
    subsys = "SimpleParams"
    user, run = handle_middle( nothing, "scotben", edition, nothing )
    change_run_state!( run; qstatus='Q', output_is_cached=false )
    minip = deepcopy( DEFAULT_MINI_PARAMS[subsys] )
    minip.taxrates[2]=25
    errs = tvalidate( minip )
    save_params( run, subsys, JSON3.write( minip ), JSON3.write( errs ))
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
    @test run.output_is_cached
    change_run_state!( run; qstatus='C', output_is_cached=true )
end
