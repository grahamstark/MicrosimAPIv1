

"""
"""
function initialise_scotben_default()
    user = get_user( DEFAULT_USER_ID )
    editions = get_available_editions( "scotben" )[1]
    no_errs = Dict{String,String}()
    for edition in editions.model_edition
        model = get_model( "scotben", edition )
        rs = rowtable(execonn( run_upsert, [user.user_id, model.name, model.edition, DEFAULT_RUN_ID, "default $(model.name) run, edition $(model.edition).", "E",true,"nodir"] ))[1]
        @show rs
        run = Run(
            rs.user_id,
            rs.model_name,
            rs.model_edition,
            rs.run_id,
            rs.run_name,
            rs.created,
            rs.last_change,
            rs.qstatus[1],
            rs.output_is_cached,
            rs.working_dir,
            RunState[],
            Dict{String,String}(),
            Dict{String,String}(),
            Dict{String,String}())
        for subsys in eachrow(get_available_subsystems( "scotben", edition )[1])
            params = DEFAULT_MINI_PARAMS[ Symbol(subsys.subsys) ]
            save_params( run, Symbol(subsys.subsys), params,no_errs )
        end
        allout = do_run( run.user_id, run.model_name, run.model_edition, run.run_id, DEFAULT_WEEKLY_PARAMS;
                        update_progress=update_progress,
                        do_dumps=true  )
        h = make_param_hash( run.user_id, run.model_name, run.model_edition, run.run_id )
        cache_output( run, h, allout )
    end
end

function initialise_database()
    load_all_parameter_descriptions()
    initialise_scotben_default()
end
