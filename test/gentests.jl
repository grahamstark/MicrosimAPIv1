

@testset "MicrosimAPIv1.jl" begin


    # Write your tests here.
end

@testset "Utils" begin
    s2 = deepcopy( MicrosimAPIv1.DEFAULT_SIMPLE_PARAMS )
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
