using MicrosimAPIv1
using .ScotbenAPIImpl

using Test
using DataFrames
using DataStructures
using Dates
using HTTP
using JSON3
using Markdown
using LoggingExtras
using Observables
using Parameters
using Random
using StructTypes
using SwaggerMarkdown
using SwagUI
using UUIDs

using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .LocalLevelCalculations
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils

using MicroVisualisations


@testset "MicrosimAPIv1.jl" begin


    # Write your tests here.
end

@testset "RiskyHash" begin
    p1 = ScotbenAPIImpl.ParamsAndSettings()
    p2 = ScotbenAPIImpl.ParamsAndSettings()
    println( "p2.hid= $(p2.hid)")
    println( "p1.settings.uuid $(p1.settings.uuid)")
    @test p2.hid == p1.hid == ScotbenAPIImpl.hid( p1 )
    res = ScotbenAPIImpl.get_cached_results( p1 )
    @test p1.hid ∈ keys(ScotbenAPIImpl.CACHED_RESULTS)
end

@testset "Default Run" begin
    ps = ScotbenAPIImpl.ParamsAndSettings()
    hid = ScotbenAPIImpl.do_run( ps; show_progress = false )
    println( "default run starting")
    hid2 = ScotbenAPIImpl.do_default_run()
    @test ps.hid == hid == hid2
    @test ps.hid ∈ keys(ScotbenAPIImpl.CACHED_RESULTS)
end
