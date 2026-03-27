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

function load_junk_into_parameters_and_output()
    conn = acquire( makeconn, CON_POOL )
    user = get_user( nothing )

    models = rowtable( execute( conn, "select * from model_versions"))
    rss = rowtable( execute( conn, "select * from result_description"))
    pss = rowtable( execute( conn, "select * from param_page_description"))
    release(CON_POOL,conn)
    for m in models
        mrun = get_run( ;
                      user_id=user.user_id,
                      model_name = m.model_name,
                      version=VersionNumber(m.model_version),
                      run_id=nothing)
            # rowtable( execute( run_upsert, [DEFAULT_USER, m.model_name, m.model_version, TEST_RUN, "default", 'E', true, "some dir"] ))[1]
        for st in pss
            data = randstring(1008)
            errors = randstring(10)
            execute( params_upsert, [user.user_id, m.model_name, m.model_version, mrun.run_id, st.name, data, errors ])
        end
        for s in rss
            data = randstring(1009)
            param_hash = rowtable(execute( hash_params, [user.user_id, m.model_name, m.model_version, mrun.run_id ]))[1].param_hash
            outputrec = execute( output_upsert, [m.model_name, m.model_version, param_hash, s.datatype, s.item, data ])
        end
    end
    return user
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


