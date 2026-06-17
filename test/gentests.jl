@testset "basic db" begin
    conn = MicrosimAPIv1.makeconn()
	@test ! isnothing(conn)
	@show conn
	LibPQ.close(conn)
	MicrosimAPIv1.clear_temp_users()
	#=
	conn = acquire( MicrosimAPIv1.makeconn, MicrosimAPIv1.CON_POOL )
	@test ! isnothing(conn)
	@show conn

	release(MicrosimAPIv1.CON_POOL,conn)

	# MicrosimAPIv1.clear_temp_users()
    =#
end


@testset "Utils" begin
    s2 = deepcopy( MicrosimAPIv1.DEFAULT_MINI_PARAMS["SimpleParams"])
    @test MicrosimAPIv1.structname( s2 ) == "SimpleParams"
    @show MicrosimAPIv1.tohtml( DataFrame())
    @show MicrosimAPIv1.struct_to_labels( s2 )
    @test length( MicrosimAPIv1.tvalidate( s2 )) == 0
    s2.taxrates[2] = 120 # max is 100
    s2.taxbands[3] = -9 # min is zero
    errs = MicrosimAPIv1.tvalidate( s2 )
    @show errs
    @test length( errs ) == 2
end
