
function makeconn()::LibPQ.Connection
    return LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")
end

const CON_POOL = Pool{LibPQ.Connection}(30)

const DEFAULT_USER = 2
const DEFAULT_RUN = 1
const TEST_RUN = 1234567890

function makeps( query :: AbstractString ) :: LibPQ.Statement
    conn = acquire( makeconn, CON_POOL )
    ps = prepare( conn, query )
    release(CON_POOL,conn)
    return ps
end

struct SimpleParams{T}
    taxrates :: Vector{T}
    taxbands :: Vector{T}
    nirates :: Vector{T}
    nibands :: Vector{T}
    taxallowance :: T
    child_benefit :: T
    pension :: T
    scottish_child_payment :: T
    scp_age :: Int
    uc_single :: T
    uc_taper :: T
end

struct User
    user_id :: Int
    email    :: String
    password :: String
    description :: String
    is_temp  :: Bool
    created :: DateTime
    expiry  :: DateTime
end

struct Model
   name :: String
   description :: String
   version :: VersionNumber
end

struct RunState
    thread_no :: Int
    phase :: String
    completed :: Int
    todo :: Int
    timer :: DateTime
end

struct OutputKey
    item :: String
    datatype :: String
end

struct OutputItem
    info :: String
    data :: String
end

mutable struct Run
    user_id :: Int
    model_name :: String
    model_version :: VersionNumber
    run_id :: Int
    run_name :: String
    submission :: DateTime
    qstatus :: Char
    output_in_sync :: Bool
    working_dir :: String
    state :: Vector{RunState}
    params :: Dict{String,String}
    errors :: Dict{String,String}
    output :: Dict{OutputKey,OutputItem}
end

const output_upsert = makeps(
    """
    insert into run_results_cache( model_name, model_version, param_hash, datatype, item, data ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, \$6 )
       on conflict( model_name, model_version, param_hash, datatype, item )
       do update
           set data = \$6
        returning *
    """)

const user_create = makeps(
    """
    insert into users( user_id, email, password, description, created, expiry, is_temp ) values
        ( \$1, \$2, \$3, \$4, now(), now()+ interval '1 day', \$5 )
    returning user_id, email, password, description, created, expiry, is_temp
    """)

const update_user_expiry = makeps(
    """
    update users set expiry = greatest( expiry, now() + interval '1 day') where user_id = \$1 returning *
    """)

const user_exists= makeps(
    """
    select count(*) as nusers from users where user_id = \$1
    """)

const run_exists= makeps(
    """
    select count(*) as nruns from runs where user_id = \$1 and model_name=\$2 and model_version=\$3 and run_id = \$4
    """)

const run_upsert = makeps(
    """
       insert into runs( user_id, model_name, model_version, run_id, run_name, submission, qstatus, output_in_sync, working_dir ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, now(), \$6, \$7, \$8 )
       on conflict( user_id, model_name, model_version, run_id )
       do update
           set qstatus=\$6, output_in_sync=\$7
        returning *
    """)

const next_free_run_id = makeps(
    """
        select coalesce(max( run_id ),0) + 1 as next_free_run_id from runs where user_id=\$1 and model_name=\$2 and model_version=\$3
    """)

const switch_run_state = makeps(
    """
        update runs set qstatus = \$1 where qstatus = \$2 and user_id=\$3 and model_name=\$4 and model_version=\$5
    """)

const change_run_state = makeps(
    """
        update runs set qstatus = \$1 where user_id=\$2 and model_name=\$3 and model_version=\$4 and run_id=\$5
    """)

#=
const copy_output = makeps(
    """
    insert into run_results select \$1, \$2, \$3, \$4, item, datatype, data from run_results where user_id=\$5 and model_name=\$2 and model_version=\$3 and run_id=\$6
    """)
=#

const params_upsert = makeps(
    """
       insert into run_params( user_id, model_name, model_version, run_id, name, data, errors ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, \$6, \$7 )
       on conflict( user_id, model_name, model_version, run_id, name )
       do update
           set data=\$6
        returning *
    """ )

const retrieve_params = makeps(
    """
    select name, data, errors from run_params where user_id=\$1 and model_name=\$2 and model_version=\$3 and run_id=\$4
    """)

const run_state_upsert = makeps(
    """
    insert into run_state( user_id, model_name, model_version, run_id, thread_no, phase, completed, todo, timer )
    values(\$1, \$2,\$3, \$4, \$5, \$6, \$7, \$8, now() ) on conflict( user_id, model_name, model_version, run_id, thread_no ) do
        update set phase=\$6, completed=\$7, todo=\$8, timer=now()
    returning *
    """)

const clear_run_states = makeps(
    """
    delete from run_state where
        user_id=\$1 and
        model_name=\$2 and
        model_version=\$3 and
        run_id=\$4 and
        thread_no >= \$5
    """
    )

const retrieve_run = makeps(
    """
    select * from runs where user_id = \$1 and model_name=\$2 and model_version=\$3 and run_id=\$4
    """)

const retrieve_cached_output_item = makeps(
    """
    select data from run_results_cache where
        model_name=\$1 and
        model_version=\$2 and
        param_hash=\$3 and
        datatype=\$4 and
        item=\$5
    """)

const retrieve_cached_output = makeps(
    """
    select run_results_cache.item,
        run_results_cache.datatype,
        result_description.info,
        run_results_cache.data from
        run_results_cache, result_description where
        run_results_cache.model_name=\$1 and
        run_results_cache.model_version=\$2 and
        run_results_cache.param_hash=\$3 and
        run_results_cache.datatype = result_description.datatype and
        run_results_cache.item = result_description.item
    """)


const hash_params = makeps(
    """
    select hashtextextended(string_agg(data,'' ORDER BY name),999) as param_hash from
        run_params where
            user_id=\$1 and
            model_name=\$2 and
            model_version=\$3
            and run_id=\$4
    """ )

const run_is_cached = makeps(
    """
    select count(*) >= 1 as is_cached from run_results_cache where
    model_name=\$1 and
    model_version=\$2 and
    param_hash=\$3
    """ )

const retrieve_model = makeps(
    """
    select models.model_name, models.description, model_versions.model_version from models, model_versions where
        models.model_name=\$1 and model_versions.model_version=\$2 and model_versions.model_name=models.model_name
    """ )

function make_param_hash( user_id :: Int, model_name::String, model_version::VersionNumber, run_id::Int)::BigInt
    rc = rowtable( execute( hash_params, [user_id, model_name, string(model_version), run_id]))[1]
    return rc.param_hash
end

function get_model( model_name :: String, version :: VersionNumber )::Model
    r = rowtable( execute( retrieve_model, [model_name, version]))[1]
    return Model( r.model_name, r.description, VersionNumber(r.model_version ))
end

function update_progress(
    user_id::Integer,
    model_name::String,
    version::VersionNumber,
    run_id::Integer,
    prog::Progress )
    #= thread_no, phase, completed, todo,
    phase  :: String
        thread :: Int
        count  :: Int
        step   :: Int
        size   :: Int
    =#
    execute( run_state_upsert, [user_id, model_name, version, run_id, prog.thread, prog.phase, prog.count, prog.size])
end

function clearup_run_states( run :: Run, delete_threads_above :: Int )
    execute( clear_run_states, [run.user_id, run.model_name, run.model_version, run.run_id, delete_threads_above ])
end

function cache_output( run :: Run, param_hash :: BigInt, allout :: AllOutput )
    model = get_model( run.model_name, run.model_version )
    for k in keys( allout.summary )
        if k == :gain_lose # gain-lose data is a sub-enum type - just the main tables here
            for gk in [:children_gl, :dec_gl, :hhtype_gl, :ten_gl]
                data = JSON3.write( allout.summary.gain_lose[2][gk]; allow_inf=true)
                execute( output_upsert, [ run.model_name, run.model_version, param_hash, "json", gk, data ] )
            end
        elseif k != :legalaid # skip Legalaid entirely
            data = JSON3.write( allout.summary[k]; allow_inf=true)
            execute( output_upsert, [ run.model_name, run.model_version, param_hash, "json", k, data ] )
        end
    end
    for k in keys( allout.html )
        execute( output_upsert, [ run.model_name, run.model_version, param_hash,  "html", k, allout.html[k] ] )
    end
    for k in keys( allout.images )
        execute( output_upsert, [ run.model_name, run.model_version, param_hash, "img", k, fig_to_svg_string(allout.images[k]) ] )
    end
end

function get_user( user_id ::Union{Int,Nothing} )::User

    function rs_to_user( r )
        rs = rowtable(r)[1]
        User( rs.user_id, rs.email, rs.description, rs.password, rs.is_temp, rs.created, rs.expiry )
    end

    function create_temp_user()
        user_id = rand(50_000:typemax(Int))
        user_data = [user_id, "no-email", hash("user_id$user_id"), "user number $user_id",true]
        rs_to_user(execute( user_create, user_data ))
    end

    function user_doesnt_exist()
        if isnothing( user_id )
            return true
        end
        rs = execute( user_exists, [user_id])
        return columntable(rs).nusers[1] != 1
    end

    return if user_doesnt_exist()
        create_temp_user()
    else
        rs_to_user(execute( update_user_expiry, [user_id]))
    end
end

function save_params( run :: Run, name::String, params :: String, errors :: String )
    execute( params_upsert, [run.user_id, run.model_name, run.model_version, run.run_id, name, params, errors ])
end

function load_params!( run :: Run;  copy_user_id::Union{Nothing,Int}=nothing, copy_run_id::Union{Nothing,Int}=nothing )
    user_id = if isnothing(copy_user_id)
        run.user_id
    else
        copy_user_id
    end
    run_id = if isnothing(copy_run_id)
        run.run_id
    else
        copy_run_id
    end
    @show user_id run_id
    p = rowtable(execute( retrieve_params, [user_id, run.model_name, run.model_version, run_id]))
    for r in p
        if (! isnothing(copy_run_id)) # we are copying in parameters from user_id
            execute( params_upsert, [run.user_id, run.model_name, run.model_version, run.run_id, r.name, r.data, r.errors ])
        end
        run.params[r.name] = r.data
        run.errors[r.name] = r.errors
    end
end

function load_output!( run :: Run;  copy_user_id::Union{Nothing,Int}=nothing, copy_run_id::Union{Nothing,Int}=nothing )
    user_id = coalesce( copy_user_id, run.user_id )
    run_id = coalesce( copy_run_id, run.run_id )
    param_hash = rowtable(execute( hash_params, [run.user_id, run.model_name, run.model_version, run.run_id]))[1].param_hash
    is_cached = rowtable(execute( run_is_cached, [run.model_name, run.model_version, param_hash]))[1].is_cached
    if is_cached
        p = rowtable(execute( retrieve_cached_output, [run.model_name, run.model_version, param_hash]))
        for r in p
            k = OutputKey( r.item, r.datatype )
            v = OutputItem( r.info, r.data )
            run.output[k] = v
        end
        # is displayed out
    else

    end
end

function create_and_save_default_scotben_run( version :: VersionNumber )
    model =
    user = get_user( DEFAULT_USER )
    models = rowtable( execute( conn, "select * from model_versions"))
    rss = rowtable( execute( conn, "select * from result_description"))
    pss = rowtable( execute( conn, "select * from param_page_description"))

end

function get_run(;
                 user_id::Int,
                 model_name :: String,
                 version :: VersionNumber,
                 run_id::Union{Int,Nothing},
                 copy_from::Union{Int,Nothing}=nothing)::Run #, copy_from_id::Union{Int,Nothing} )::Run

    function rs_to_run( r )
        rs = rowtable(r)[1]
        return Run( rs.user_id,
                    rs.model_name,
                    VersionNumber( rs.model_version ),
                    rs.run_id,
                    rs.run_name,
                    rs.submission,
                    rs.qstatus[1],
                    rs.output_in_sync,
                    rs.working_dir,
                    RunState[],
                    Dict{String,String}(),
                    Dict{String,String}())
    end

    function run_doesnt_exist()
        if isnothing( run_id )
            return true
        end
        rs = execute( run_exists, [user_id, model_name, version, run_id])
        return columntable(rs).nruns[1] == 0
    end

    function retrieve_live_run()
        r = execute( retrieve_run, [user_id, model_name, version, run_id])
        rs_to_run( r )
    end

    function get_next_free_run_id()::Int
        r = execute( next_free_run_id, [user_id, model_name, version])
        return columntable(r).next_free_run_id[1]
    end

    function create_run()
        new_run_id = get_next_free_run_id()
        d = joinpath( tempdir(), "$(user_id)", "$(model_name)", "$(version)", "$(run_id)")
        path = mkpath(d)
        run_params = [user_id, model_name, version, new_run_id, "", "E", false, path]
        rs = execute( run_upsert, run_params )
        run = rs_to_run( rs )
        copyrun = if isnothing( copy_from )
            r = execute( retrieve_run, [DEFAULT_USER, model_name, version, DEFAULT_RUN])
            rs_to_run( r )
        else
            @show  [user_id, model_name, version, copy_from ]
            r = execute( retrieve_run, [user_id, model_name, version, copy_from ])
            rs_to_run( r )
        end
        return run
    end

    run = if run_doesnt_exist()
        # create_run
        create_run()
    else
        retrieve_live_run()
    end
    load_params!( run )
    load_output!( run )
    return run
end

function handle_middle( user_id ::Union{Int,Nothing}, run_id :: Union{Int,Nothing}, model_name::String,  version :: VersionNumber )::Integer
    user = get_user( user_id )
    run = get_run( user_id, run_id, model_name, version )

end
