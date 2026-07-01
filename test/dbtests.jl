
@testset "DB Middleware" begin
    initialise_database()
    global uid
    models = get_available_models()[1]
    @test size(models)[1] >= 1 # at least 1 model
    for m in eachrow(models)
        editions = get_available_editions( m.model_name )[1]
        @test size(editions)[1] >= 1 # at least 1 model
        for e in eachrow( editions )
            model = get_model( m.model_name, e.model_edition )
            @test model.name == m.model_name
            ss = get_available_subsystems( model.name, e.model_edition )[1]
            @test size(ss)[1] >= 1 # at least 1 subsystem
            for s in eachrow(ss)
                minip=DEFAULT_MINI_PARAMS[Symbol(s.subsys)]
            end
        end
    end
    # middleware thing test
    user, run = handle_middle( uid, "scotben", "simple-2026a", nothing )
    # @test user.user_id != uid # should have a new uid, but keep it from now on.
    @test run.user_id == user.user_id
    uid = user.user_id # save global user id
    # try again - should persist this time
    user2, run2 = handle_middle( user.user_id, run.model_name, run.model_edition, nothing )
    # check we've brought back the same user and run this time
    @test user2.user_id == user.user_id
    @test run2.run_id == run.run_id
end

@testset "output cache tests" begin
    subsys = :SimpleParams
    minip=deepcopy(DEFAULT_MINI_PARAMS[subsys])
    user, run = handle_middle( uid, "scotben", "simple-2026a", nothing )
    @test run.output_is_cached # default
    minip.taxrates .+= rand()
    run.params[subsys] = JSON3.write( minip )
    save_params( run, subsys, run.params[subsys], Dict() )
    user, run = handle_middle( uid, "scotben", "simple-2026a", nothing )
    @test ! run.output_is_cached
end
