#=
Database functions in Julia.

Initialise the microapt database with
    `db/microapt.sql'
then load Scotben stuff with 'initialise_database()' below.

=#
const DEFAULT_USER_ID = 2
const DEFAULT_RUN_ID = 1
const TEST_RUN_ID = 1234567890

function makeconn()::LibPQ.Connection
    return LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")
end

"""
Execute a statement with a throwaway connection
"""
function execonn( statement::String, data::AbstractArray)
    conn = makeconn()
    r = execute( conn, statement, data )
    close(conn)
    return r
end

function execonn( statement::String)
    return execonn( statement, [] )
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
   # subsys :: String
   description :: String
   edition :: String
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
    model_edition :: String
    run_id :: Int
    run_name :: String
    created :: DateTime
    last_change :: DateTime
    qstatus :: Char 
    output_is_cached :: Bool
    working_dir :: String
    state :: Vector{RunState}
    params :: Dict{Symbol,Subsys}
    errors :: Dict{Symbol,Dict}
    output :: Dict{OutputKey,OutputItem}
end

"""
return true if run has no errors, & dict with errors for each subsys
"""
function has_no_errors( run :: Run )::Tuple
    anyerrs = filter(x->length(x[2])>0,run.errors)
    return length(anyerrs)==0, anyerrs
end

const user_queue_counts =
    """
    select qstatus,count(*)  as qcount from runs where user_id=\$1 group by qstatus
    """

const total_queue_counts =
    """
    select qstatus,count(*) as qcount from runs group by qstatus
    """
const output_upsert =
    """
    insert into run_results_cache( model_name, model_edition, param_hash, datatype, item, data ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, \$6 )
       on conflict( model_name, model_edition, param_hash, datatype, item )
       do update
           set data = \$6
        returning *
    """

const user_create =
    """
    insert into users( user_id, email, password, description, created, expiry, is_temp ) values
        ( \$1, \$2, \$3, \$4, now(), now()+ interval '1 day', \$5 )
    returning user_id, email, password, description, created, expiry, is_temp
    """

const update_user_expiry =
    """
    update users set expiry = greatest( expiry, now() + interval '1 day') where user_id = \$1 returning *
    """

const user_exists =
    """
    select count(*) as nusers from users where user_id = \$1
    """

const run_in_state_exists =
    """
    select count(*) as nruns from runs where user_id = \$1 and model_name=\$2 and model_edition=\$3 and qstatus = \$4
    """

const run_upsert =
    """
       insert into runs( user_id, model_name, model_edition, run_id, run_name, created, last_change, qstatus, output_is_cached, working_dir ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, now(), now(), \$6, \$7, \$8 )
       on conflict( user_id, model_name, model_edition, run_id )
       do update
           set last_change = now(), qstatus=\$6, output_is_cached=\$7
        returning *
    """
const run_update =
    """
       update runs set run_name=\$1, last_change=now(), qstatus=\$2, output_is_cached=\$3, working_dir=\$4
           where user_id=\$5 and model_name=\$6 and model_edition=\$7 and run_id=\$8 returning *
    """

const next_free_run_id =
    """
        select coalesce(max( run_id ),0) + 1 as next_free_run_id from runs where user_id=\$1 and model_name=\$2 and model_edition=\$3
    """

const switch_run_state =
    """
        update runs set qstatus = \$1 where qstatus = \$2 and user_id=\$3 and model_name=\$4 and model_edition=\$5
    """

const change_run_state =
    """
        update runs set qstatus = \$5, output_is_cached=\$6 where user_id=\$1 and model_name=\$2 and model_edition=\$3 and run_id=\$4
    """
const params_upsert =
    """
       insert into run_params( user_id, model_name, model_edition, run_id, subsys,  data, errors ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, \$6, \$7 )
       on conflict( user_id, model_name, model_edition, run_id, subsys )
       do update
           set data=\$6
        returning *
    """

const retrieve_params =
    """
    select subsys,  data, errors from run_params where user_id=\$1 and model_name=\$2 and model_edition=\$3 and run_id=\$4
    """

const get_run_state = """
    select * from run_state where user_id=\$1 and model_name=\$2 and model_edition=\$3 and run_id=\$4
"""


const run_state_upsert =
    """
    insert into run_state( user_id, model_name, model_edition, run_id, thread_no, phase, completed, todo, timer )
    values(\$1, \$2,\$3, \$4, \$5, \$6, \$7, \$8, now() ) on conflict( user_id, model_name, model_edition, run_id, thread_no ) do
        update set phase=\$6, completed=\$7, todo=\$8, timer=now()
    returning *
    """

const clear_run_states =
    """
    delete from run_state where
        user_id=\$1 and
        model_name=\$2 and
        model_edition=\$3 and
        run_id=\$4 and
        thread_no >= \$5
    """

const retrieve_latest_run =
    """
    select * from runs where user_id = \$1 and model_name=\$2 and model_edition=\$3 and qstatus=\$4 order by last_change limit 1;
    """

const retrieve_numbered_run =
    """
    select * from runs where user_id = \$1 and model_name=\$2 and model_edition=\$3 and run_id =\$4
    """

const retrieve_cached_output_item =
    """
    select data from run_results_cache where
        model_name=\$1 and
        model_edition=\$2 and
        param_hash=\$3 and
        datatype=\$4 and
        item=\$5
    """

const retrieve_cached_output =
    """
    select run_results_cache.item,
        run_results_cache.datatype,
        result_description.info,
        run_results_cache.data from
        run_results_cache, result_description where
        run_results_cache.model_name=\$1 and
        run_results_cache.model_edition=\$2 and
        run_results_cache.param_hash=\$3 and
        run_results_cache.datatype = result_description.datatype and
        run_results_cache.item = result_description.item
    """

const hash_params =
    """
    select hashtextextended(string_agg(data,'' ORDER BY subsys),999) as param_hash from
        run_params where
            user_id=\$1 and
            model_name=\$2 and
            model_edition=\$3
            and run_id=\$4
    """

const run_is_cached =
    """
    select count(*) >= 1 as is_cached from run_results_cache where
    model_name=\$1 and
    model_edition=\$2 and
    param_hash=\$3
    """

const retrieve_model =
    """
    select models.model_name, models.description, model_editions.model_edition from models, model_editions where
        models.model_name=\$1 and model_editions.model_edition=\$2 and model_editions.model_name=models.model_name
    """


function get_avaliable_models_and_versions()::AbstractDataFrame
    r = rowtable( execonn( """
        select models.model_name, models.description as model_desc, model_edition, model_editions.description as edition_desc from model_editions, models where model_editions.model_name = models.model_name
        """))
    return DataFrame(r)
end

function  get_all_q_statuses()
    r = columntable( execonn( "select qstatus from q_statuses"))
    return map( x -> x[1], r.qstatus ) # this casts to Chars
end

const Q_STATUSES = get_all_q_statuses()

function get_queue_counts( user_id :: Union{Int,Nothing} = nothing )::Dict{Char,Integer}
    runs = if isnothing( user_id )
        rowtable(execute( total_queue_counts ))
    else
        rowtable(execute( user_queue_counts, [user_id] ))
    end
    d = Dict{Char,Integer}()
    for k in Q_STATUSES
        d[k] = 0 # the [1] forces the key to be Char
    end
    for r in runs
        d[r.qstatus[1]] = r.qcount
    end
    return d;
end

"""


"""
function load_parameter_description( model::String, edition::String, title::String, thestruct )::DataFrame
    info = struct_to_labels(thestruct)
     # use the type pf the strict as the subsys name, but strip e.g. "{Float64}" from the end
    subsys = structname( thestruct )
    r = DataFrame( execonn( """
        insert into param_page_description values( \$1, \$2, \$3, \$4, \$5 )
        on conflict( model_name, model_edition, subsys )
        do update
            set title = \$4, info=\$5
        returning *
    """, [model, edition, subsys, title, info]))
    return r
end

"""
NOTE: you need BASE_RESULTS = do_default_run() first if you're not loading MicrosimAPIv1
"""
function load_all_parameter_descriptions() # so far
    load_parameter_description("scotben", "simple-2026a", "A Basic Set of SB Parameters", DEFAULT_MINI_PARAMS[:SimpleParams] )
    load_parameter_description("scotben", "basic-income-2026a", "Basic Income Simulation Parameters", DEFAULT_MINI_PARAMS[:UBIParams] )
end

function get_available_models()::Tuple
    r = execonn( "select * from models")
    return DataFrame( r ), rowtable(r)
end

function get_available_editions( model :: String )::Tuple
    r = execonn( "select * from model_editions where model_name=\$1", [model])
    return DataFrame(r), rowtable(r)
end

function get_available_subsystems( model::String, edition :: String )::Tuple
    r = execonn( "select * from param_page_description where model_name=\$1 and model_edition=\$2", [model,edition])
    return DataFrame( r ), rowtable( r )
end

function get_parameter_descriptions( model::String, edition :: String, subsys :: String )::Tuple
    r = execonn( "select * from param_page_description where model_name=\$1 and model_edition=\$2 and subsys=\$3", [model,edition,subsys])
    return DataFrame( r ), rowtable(r)
end

function get_output_descriptions( model::String ) ## add edition???
    r = execonn( "select * from result_description where model_name=\$1 order by model_name,datatype,item", [model])
    return DataFrame( r ), rowtable(r)
end

function make_param_hash( user_id :: Int, model_name::String, model_edition::String, run_id::Int)::BigInt
    rc = rowtable( execonn( hash_params, [user_id, model_name, string(model_edition), run_id]))[1]
    return rc.param_hash
end

function get_model( model_name :: String, edition :: String )::Model
    r = rowtable( execonn( retrieve_model, [model_name, edition]))[1]
    return Model( r.model_name, r.description, String(r.model_edition ))
end

function update_progress(
    user_id::Integer,
    model_name::String,
    edition::String,
    run_id::Integer,
    prog::Progress )
    execonn( run_state_upsert, [user_id, model_name, edition, run_id, prog.thread, prog.phase, prog.count, prog.size])
end

function clearup_run_states( run :: Run, delete_threads_above :: Int )
    execonn( clear_run_states, [run.user_id, run.model_name, run.model_edition, run.run_id, delete_threads_above ])
end

"""
for now, just cache SVG and HTML output
"""
function cache_output( run :: Run, param_hash :: BigInt, allout :: AllOutput )
    model = get_model( run.model_name, run.model_edition )
    for k in keys( allout.html )
        execonn( output_upsert, [ run.model_name, run.model_edition, param_hash,  "html", k, allout.html[k].data ] )
    end
    for k in keys( allout.images )
        execonn( output_upsert, [ run.model_name, run.model_edition, param_hash, "svg", k, mv.fig_to_svg_string(allout.images[k].data) ] )
    end
    # just the filename of the phunpack, not the zip data
    execonn( output_upsert, [ run.model_name, run.model_edition, param_hash, "zip", "phunpack", allout.phunpack ])
    run.output_is_cached = true
end

"""
retrieve a User struct for user `user_id`. If that doesn't exist, create a new temp user. In either case,
increment the expiry time for the user by 1 day.
"""
function get_user( user_id ::Union{Int,Nothing} )::User

    function rs_to_user( r )
        rs = rowtable(r)[1]
        User( rs.user_id, rs.email, rs.description, rs.password, rs.is_temp, rs.created, rs.expiry )
    end

    function create_temp_user()
        user_id = rand(50_000:typemax(Int))
        user_data = [user_id, "no-email", hash("user_id$user_id"), "user number $user_id",true]
        rs_to_user(execonn( user_create, user_data ))
    end

    function user_doesnt_exist()
        if isnothing( user_id )
            return true
        end
        rs = execonn( "select count(*) as nusers from users where user_id = \$1", [user_id])
        return columntable(rs).nusers[1] != 1
    end

    return if user_doesnt_exist()
        create_temp_user()
    else
        rs_to_user(execonn( update_user_expiry, [user_id]))
    end
end

function save_params( run :: Run, subsys::Symbol, params :: Subsys, errors :: AbstractDict )
    execonn( params_upsert, [run.user_id, run.model_name, run.model_edition, run.run_id, string(subsys), JSON.json( params ), JSON.json( errors ) ])
end


output_is_cached( run :: Run, param_hash :: Integer )::Bool =
    rowtable(execonn( run_is_cached, [run.model_name, run.model_edition, param_hash]))[1].is_cached

function all_errs( run :: Run )
    merge( values( run.errs ))
end

"""
Load parameters into the run rec. if copy_user_id and copy_run_id are both not nothing, copy in parameters
from that run, otherwise load whatever parameters have already been stored for the run. Sets output_is_cached
as a side-effect.
"""
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
    p = rowtable(execonn( retrieve_params, [user_id, run.model_name, run.model_edition, run_id]))
    for r in p
        if (! isnothing(copy_run_id)) # we are copying in parameters from user_id, FIXME maybe don't bother doing this yer
            execonn( params_upsert, [run.user_id, run.model_name, run.model_edition, run.run_id, r.subsys, r.data, r.errors ])
        end
        ss = Symbol( r.subsys )
        T = eval( ss )
        run.params[ss] = JSON.parse( r.data, T{Float64} )
        run.errors[ss] = try
            JSON.parse( r.errors, Dict )
        catch e
            Dict()
        end
    end
    hash = make_param_hash( run.user_id, run.model_name, run.model_edition, run.run_id )
    run.output_is_cached = output_is_cached( run, hash )
end

function load_output!( run :: Run;  copy_user_id::Union{Nothing,Int}=nothing, copy_run_id::Union{Nothing,Int}=nothing )
    user_id = coalesce( copy_user_id, run.user_id )
    run_id = coalesce( copy_run_id, run.run_id )
    hash = make_param_hash( run.user_id, run.model_name, run.model_edition, run.run_id )
    if output_is_cached( run, hash )
        run.output_is_cached = true
        p = rowtable(execonn( retrieve_cached_output, [run.model_name, run.model_edition, hash]))
        for r in p
            k = OutputKey( r.item, r.datatype )
            v = OutputItem( r.info, r.data )
            run.output[k] = v
        end
        # is displayed out
    else
        run.output_is_cached = false
    end
end

"""
rs is a row from a rowtable. Convert this to a Run record. FIXME: argcheck that's what r really is somehow..
"""
function rs_to_run( rs )::Run
    # @argcheck istable( rs )
    return Run( 
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
        Dict{Symbol,Subsys}(),
        Dict{Symbol,Subsys}(),
        Dict{Symbol,Subsys}())
end

function change_run_state!( run :: Run; qstatus :: Char, output_is_cached :: Bool )
    run.qstatus = qstatus
    run.output_is_cached = output_is_cached
    execonn( change_run_state, [run.user_id, run.model_name, run.model_edition, run.run_id, qstatus, output_is_cached ])
end

"""
retrieve or create a run

* @param copy_from: if no currently edited run, make a copy of the run with this id for the user, otherwise make a copy of the default for this model&edition
"""
function get_run(
                 user_id::Int,
                 model_name :: String,
                 edition :: String,
                 copy_from::Union{Int,Nothing}=nothing)::Run

    function get_next_free_run_id()::Int
        r = execonn( next_free_run_id, [user_id, model_name, edition])
        return columntable(r).next_free_run_id[1]
    end

    function create_run()
        new_run_id = get_next_free_run_id()
        d = joinpath( tempdir(), "$(user_id)", "$(model_name)", "$(edition)", "$(new_run_id)")
        path = mkpath(d)
        run_params = [user_id, model_name, edition, new_run_id, "", "E", false, path]
        run = rowtable(execonn( run_upsert, run_params ))[1]|> rs_to_run
        # run = rs_to_run( rs )
        copyrun = if isnothing( copy_from )
            rs = rowtable(execonn( retrieve_numbered_run, [DEFAULT_USER_ID, model_name, edition, DEFAULT_RUN_ID]))[1]
            rs_to_run( rs )
        else
            @show  [user_id, model_name, edition, copy_from ]
            rs = rowtable(execonn( retrieve_numbered_run, [user_id, model_name, edition, copy_from ]))[1]
            rs_to_run( rs )
        end
        load_params!( run;  copy_user_id=copyrun.user_id, copy_run_id=copyrun.run_id )
        load_output!( run;  copy_user_id=copyrun.user_id, copy_run_id=copyrun.run_id )
        execonn( change_run_state, [run.user_id, run.model_name, run.model_edition, run.run_id, 'E', true ])
        # demote the copied run if not the default
        if(copyrun.user_id == run.user_id) && (copyrun.qstatus in ['E'])
            execonn( change_run_state, [copyrun.user_id, copyrun.model_name, copyrun.model_edition, copyrun.run_id,'C', copyrun.output_is_cached])
        end
        return run
    end # create run

    rs = rowtable(execonn( retrieve_latest_run, [user_id, model_name, edition, 'E']))
    l = length(rs)
    @assert l in 0:1
    return if l == 1 # there's a latest run in 'Edit' state
        run = rs_to_run( rs[1] )
        load_params!( run )
        load_output!( run )
        run
    else # no run
        create_run()
    end
end

"""
Save the run and parameters, but not output and the run_states. Not an upsert so only works if run exists in DB.
"""
function save_run( run :: Run )
    for (k,v) in run.params
        err = Base.get( run.errors, k, Dict())
        # errs = JSON.json( err )
        save_params( run, k, v, err )
    end
    run_params = [run.run_name, run.qstatus, run.output_is_cached, run.working_dir, run.user_id, run.model_name, run.model_edition, run.run_id ]
    execonn( run_update, run_params )
end

function clear_expired_temp_users()
    execonn( "delete from users where is_temp and expiry < now()");
end

function clear_all_temp_users()
    execonn( "delete from users where is_temp");
end

"""
Return a user and a run record for that user, creating both if needed.

If the user is `nothing` or a number not in the db, make a new temporary user and an initialised run with default outputs and parameters.

Othewise, retrieve the user and its active run (might not actually have been run yet). The created run is a copy of `copy_from` if that exists (e.g.) the user's previous run, or else a copy of the default run.

"""
function handle_middle( user_id ::Union{Int,Nothing},
                        model_name::String,
                        edition :: String,
                        copy_from::Union{Int,Nothing}=nothing )::Tuple
    user = get_user( user_id )
    runrec = get_run( user.user_id, model_name, edition, copy_from )
    return user, runrec
end



"""
return the earliest queued run rec or nothing.
"""
function next_runnable_run()::Union{Run,Nothing}
    r = rowtable(execonn( "select * from runs where qstatus='Q' order by last_change limit 1"))
    return if length( r ) == 0
        nothing
    else
        rs_to_run( r[1] )
    end
end

"""
return progress as an array (poss 0 length) of named tuples
"""
function get_run_progress( run :: Run )
    return rowtable(execonn( get_run_state, [run.user_id, run.model_name, run.model_edition, run.run_id]))
end