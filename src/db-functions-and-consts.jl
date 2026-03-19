using LibPQ, DataFrames,ConcurrentUtilities.Pools,Dates,Random,Tables
using ScottishTaxBenefitModel
using .STBParameters

function makeconn()::LibPQ.Connection
    return LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")
end

const CON_POOL = Pool{LibPQ.Connection}(10)

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

mutable struct Run
    run_id :: Int
    run_name :: String
    submission :: DateTime
    qstatus :: Char
    output_in_sync :: Bool
    working_dir :: String
    state :: Vector{RunState}
    params :: Dict{String,String}
    output :: Dict{String,String}
end

const user_create = makeps(
    """
    insert into users( user_id, email, password, description, created, expiry, is_temp ) values
        ( \$1, \$2, \$3, \$4, now(), now()+ interval '1 day', \$5 )
    returning user_id, email, password, description, created, expiry, is_temp
    """
    )

const update_user_expiry = makeps(
    """
    update users set expiry = greatest( expiry, now() + interval '1 day') where user_id = \$1 returning *
    """ )

const user_exists= makeps(
    """
    select count(*) as nusers from users where user_id = \$1
    """ )

const run_exists= makeps(
    """
    select count(*) as nruns from runs where user_id = \$1 and model_name=\$2 and model_version=\$3 and run_id = \$4
    """ )

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
    """ )

const switch_run_state = makeps(
    """
        update runs set qstatus = \$1 where qstatus = \$2 and user_id=\$3 and model_name=\$4 and model_version=\$5
    """)

const change_run_state = makeps(
    """
        update runs set qstatus = \$1 where user_id=\$2 and model_name=\$3 and model_version=\$4 and run_id=\$5
    """)

const copy_parameters = makeps(
    """
    insert into run_params values(
            \$1, \$2, \$3, \$4, \$5, (select data from run_params where user_id=2 and model_name=\$2 and model_version=\$3 ))
    """)

const copy_output = makeps(
    """
    insert into run_results values(
            \$1, \$2, \$3, \$4, \$5, (select data from run_results where user_id=2 and model_name=\$2 and model_version=\$3 ))
    """
    )

const parameters_upsert = makeps(
    """
       insert into run_params( user_id, model_name, model_version, run_id, name, data ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5 )
       on conflict( user_id, model_name, model_version, run_id, name )
       do update
           set data=\$5
        returning *
    """
    )

const output_upsert = makeps(
    """
       insert into run_results( user_id, model_name, model_version, run_id, datatype, item, data ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, \$6 )
       on conflict( user_id, model_name, model_version, run_id, item, datatype )
       do update
           set data=\$6
        returning *
    """

    )

const run_state_upsert = makeps(
    """
    insert into run_state( user_id, model_name, model_version, run_id, thread_no, phase, completed, todo, timer )
    values(\$1, \$2,\$3, \$4, \$5, \$6, \$7, \$8, now() ) on conflict( user_id, model_name, model_version, run_id, thread_no ) do
        update set phase=\$9, completed=\$10, todo=\$11, timer=now()
    returning *
    """)

const retrieve_run = makeps(
    """
    select * from runs where user_id = \$1 and model_name=\$2 and model_version=\$3 and run_id=\$4
    """
    )

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

function get_run(; user_id::Int, model_name :: String, version :: VersionNumber, run_id::Union{Int,Nothing},  )::Run

        function rs_to_run( r )
            rs = rowtable(r)[1]
            return Run( rs.run_id, rs.run_name, rs.submission, rs.qstatus[1], rs.output_in_sync, rs.working_dir,
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
            run_id = get_next_free_run_id()
            d = joinpath( tempdir(), "$(user_id)", "$(model_name)", "$(version)", "$(run_id)")
            path = mkpath(d)
            run_params = [user_id, model_name, version, run_id, "", "E", false, path]
            rs = execute( run_upsert, run_params )
            rs_to_run( rs )
        end

    return if run_doesnt_exist()
        # create_run
        create_run()
    else
        retrieve_live_run()
    end
end

function handle_middle( user_id ::Union{Int,Nothing}, run_id :: Union{Int,Nothing}, model_name::String,  version :: VersionNumber )::Integer
    user = get_user( user_id )
    run = get_run( user_id, run_id, model_name, version )

end
