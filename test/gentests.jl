@testset "basic db" begin
    conn = msa.makeconn()
	@test ! isnothing(conn)
	@show conn
	LibPQ.close(conn)
	msa.clear_temp_users()

end


@testset "Utils" begin
    s2 = deepcopy( msa.DEFAULT_MINI_PARAMS["SimpleParams"])
    @test msa.structname( s2 ) == "SimpleParams"
    @show msa.tohtml( DataFrame())
    @show msa.struct_to_labels( s2 )
    @test length( msa.tvalidate( s2 )) == 0
    s2.taxrates[2] = 120 # max is 100
    s2.taxbands[3] = -9 # min is zero
    errs = msa.tvalidate( s2 )
    @show errs
    @test length( errs ) == 2
end


@testset "DB Middleware" begin
    msa.initialise_database()
    models = msa.get_available_models()
    @test size(models)[1] >= 1 # at least 1 model
    for m in eachrow(models)
        editions = msa.get_available_editions( m.model_name )
        @test size(editions)[1] >= 1 # at least 1 model
        for e in eachrow( editions )
            model = msa.get_model( m.model_name, e.model_edition )
            @test model.name == m.model_name
            ss = msa.get_available_subsystems( model.name, e.model_edition )
            @test size(ss)[1] >= 1 # at least 1 subsystem
            for s in eachrow(ss)
                @show s
            end
        end
    end
    # middleware thing test
    uid = 123456
    user, runrec = msa.handle_middle( uid, "scotben", "simple-2026a", nothing )
    @test user.user_id != uid
    @test runrec.user_id == user.user_id
    # try again - should persist this time
    user2, runrec2 = msa.handle_middle( user.user_id, runrec.model_name, runrec.model_edition, nothing )
    # check we've brought back the same user and run this time
    @test user2.user_id == user.user_id
    @test runrec2.run_id == runrec.run_id
end

@testset "Model Run" begin
    uid = nothing
    no_errs = Dict()
    edition = "simple-2026a"
    subsys = "SimpleParams"
    user, runrec = msa.handle_middle( uid, "scotben", edition, nothing )
    minip = deepcopy( msa.DEFAULT_MINI_PARAMS )
    minip.taxbands=[]
    minip.taxrates=[25]
    errs = msa.tvalidate( minip )
    msa.save_params( runrec, subsys, JSON3.write( params ), JSON3.write( errs ))

    sys = deepcopy( msa.DEFAULT_PARAMS )
    map_simple_to_full!( sys, minip )

end
