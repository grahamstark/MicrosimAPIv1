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

function load_junk_into_parameters_and_output(user_id=DEFAULT_USER, run_id=TEST_RUN)
    conn = acquire( makeconn, CON_POOL )
    user = get_user( user_id )
    @assert user.user_id == user_id

    models = rowtable( execute( conn, "select * from model_versions"))
    rss = rowtable( execute( conn, "select * from result_description"))
    pss = rowtable( execute( conn, "select * from param_page_description"))
    release(CON_POOL,conn)
    @time for m in models
        run = get_run( ; user_id=user_id, model_name = m.model_name, version=VersionNumber(m.model_version), run_id=run_id )
            # rowtable( execute( run_upsert, [DEFAULT_USER, m.model_name, m.model_version, TEST_RUN, "default", 'E', true, "some dir"] ))[1]
        @assert run.run_id == run_id
        for s in rss
            data = randstring(1009)
            execute( output_upsert, [user_id, m.model_name, m.model_version, run.run_id, s.datatype, s.item, data ])
        end
        for st in pss
            data = randstring(1009)
            execute( params_upsert, [user_id, m.model_name, m.model_version, run.run_id, st.name, data ])
        end
    end
end


@testset "Load Tests" begin
    users = []
    runs = []
    conn = acquire( makeconn, CON_POOL )
    models = rowtable( execute( conn, "select * from models"))
    release(CON_POOL,conn)
    load_junk_into_parameters_and_output()
    for m in models
        for i in 100:10000
            u = get_user( nothing )
            r = get_run( u.user_id, m.model_name, m.model_version, nothing )

            push!(users,u)
            push!( runs, r )
        end
    end
end


