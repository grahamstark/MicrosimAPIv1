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

const

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
    select count(*) as nruns from runs where user_id = \$1 and run_id = \$2
    """ )

const run_upsert = makeps(
    """
       insert into runs( user_id, model_name, model_version, run_id, run_name, submission, qstatus, output_in_sync ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, now(), \$6, \$7 )
       on conflict( user_id, model_name, model_version, run_id )
       do update
           set qstatus=\$8, output_in_sync=\$9
        returning *
    """)

const next_free_run_id = makeps(
    """
        select max( run_id ) + 1 as next_free_run_id from runs where user_id=\$1 and model_name=\$2 and model_version=\$3
    """ )

const switch_run_state = makeps(
    """
        update runs set qstatus = \$1 where qstatus = \$2 and user_id=\$3 and model_name=\$4 and model_version=\$5
    """)

const change_run_state = makeps(
    """
        update runs set qstatus = \$1 where user_id=\$2 and model_name=\$3 and model_version=\$4 and run_id=\$5
    """)

const add_parameters = makeps(
    """
    insert into run_params values(
            \$1, \$2, \$3, \$4, \$5, (select data from run_params where user_id=2 and model_name=\$2 and model_version=\$3 ))
    """)

const run_state_upsert = makeps(
    """
    insert into run_state( user_id, model_name, model_version, run_id, thread_no, phase, completed, todo, timer )
    values(\$1, \$2,\$3, \$4, \$5, \$6, \$7, \$8, now() ) on conflict( user_id, model_name, model_version, run_id, thread_no ) do
        update set phase=\$9, completed=\$10, todo=\$11, timer=now()
    returning *
    """)

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

function get_run( user_id::Int, run_id::Union{Int,Nothing}, model_name :: String, version :: VersionNumber )::Run

        function rs_to_run( r )
            rs = rowtable(r)[1]
            return Run( rs.run_id, rs.submission, rs.qstatus, rs.output_in_sync, rs.working_dir, rs.state, State[], Dict{String,String}())
        end

        function run_doesnt_exist()
            if isnothing( run_id )
                return true
            end
            rs = execute( run_exists, [user_id,run_id])
            return columntable(rs).nruns[1] != 1
        end

        function retrieve_run()

        end

        function get_next_free_run_id()::Int
            rs = execute( next_free_run_id, [user_id, model_name, version])
            return columntable(rs).next_free_run_id[1]
        end

        function create_run()
            run_id = get_next_free_run_id()
            d = joinpath( tmpdir(), "$(user_id)", "$(model_name)", "$(version)", "$(run_id)")
            path = mkpath(d)
            run_params = [user_id, model_name, version, run_id, "", "E", false, true, "E", true]
            rs = execute( run_upsert, run_params )
            rs_to_run( rs )
        end

    return if run_doesnt_exist()
        # create_run
        create_run()
    else
        retrieve_run()
    end
end

function handle_middle( user_id ::Union{Int,Nothing}, run_id :: Union{Int,Nothing}, model_name::String,  version :: VersionNumber )::Integer
    user = get_user( user_id )
    run = get_run( user_id, run_id, model_name, version )

end

#=
function create_temp_user()::Union{Nothing,User}
    user_id = rand(50_000:typemax(Int))
    conn = makeconn()
    try
        execute( conn, "insert into users( user_id, email, password, description, created, expiry, is_temp ) values( $user_id, '', '', 'a temp user', now(), now() + interval '1 day', true )" )
        catch e
        @show "create_temp_user errored with " e
        close(conn)
        return nothing
    end
    u = get_user( conn, user_id)
    close(conn)
    return u
end



run_params = [2,"scotben","0.17",1, "some uuid","E",false,true,"X",false,true]
execute( run_upsert, run_params )
run_state_params = [2,"scotben","0.17",1, 2,"running",999,10_000,"running",2000,10_000]
execute( run_state_upsert, run_state_params )


insert into runs( user_id, model_name, model_version, run_id, run_name, submission, qstatus, is_displayed, is_edited )
values(1,'scotben','0.17',1,'some name', now(), 'E', false, true ) on conflict( user_id, model_name, model_version, run_id ) do
    update set qstatus=?, is_displayed=?, is_edited=?;

    update users set expiry = now()+duration '1 day' where user_id=?

    insert into run_state( user_id, model_name, model_version, run_id, thread_no, phase, completed, todo, timer )
    values(1,'scotben','0.17', 1, 1, 'running', 1000, 9000, now() ) on conflict( user_id, model_name, model_version, run_id, thread_no ) do
        update set phase='running', completed=3000, todo=9000, timer=now();

        delete from run_state where user_id=? and model_name=? and model_version=? and run_id =? and thread_id > ?;



        user_id bigint not null,
        model_name char(20) not null default 'scotben',
        model_version char(12) not null default '0.17',
        run_id integer not null,
        thread_no int default 1,
        phase text not null,
        completed integer default 0,
        todo integer,
        timer timestamp,


function t10k()
    @time for i in 1:50_000
        u=create_temp_user()
        if (i % 2000)==0
            println(u.user_id)
        end
    end
end

function t10k2()
    @time for i in 1:50_000
        u=create_temp_user_faster()
        if (i % 2000)==0
            println(u.user_id)
        end
    end
end


user_retrieve = makeps(
    """
    select user_id, email, password, description, created, expiry, is_temp from users where user_id = \$1
    """
)

function get_user2( user_id :: Integer )
end


function create_temp_user_faster()::Union{Nothing,User}
    u = get_user2( user_id)
    return u
end
conn3 = makeconn()
vins = prepare( conn, "insert into model_versions values( \$1, \$2, \$3 )")
@time for c in 20_000:21_000
    v = VersionNumber(string(c))
    execute( vins, ["scotben",v,"version $v"])

end
close(conn3)

@time for c in 3001:4_000
    conn3 = makeconn()

    vins = prepare( conn, "insert into model_versions values( \$1, \$2, \$3 )")
    v = VersionNumber(string(c))
    execute( vins, ["scotben",v,"version $v"])
    close(conn3)
end
# 2.880808

@time for c in 40_000:41_000
    v = VersionNumber(string(c))
    execute( vins, ["scotben",v,"version $v"])
end

execute( conn, "delete from model_versions where model_version <> '0.10'")
# 1.164591 seconds (105.11 k allocations: 3.987 MiB)
function makeps( statement )
    conn = makeconn()
    ps = prepare(conn, statement )
end


conn = acquire( makeconn, CON_POOL )
ps = acquire( makeps, PS_POOL )

result = execute(conn, "SELECT * from users")

ps = prepare(conn, "select username from users where is_temp = \$1")

r2 = execute(ps,[true])
DataFrame(r2)

ins = prepare( conn, "insert into models values( \$1, \$2 )")

result = execute( ins, ["lanman", "Howards Model"])


vins = prepare( conn, "insert into model_versions values( \$1, \$2, \$3 )")


result = execute( vins, ["lanman", Decimal(0.1), "Howards Model"])


@time for c in 1:1_000
    conn3 = makeconn()

    vins = prepare( conn, "insert into model_versions values( \$1, \$2, \$3 )")
    v = VersionNumber(string(c))
    execute( vins, ["scotben",v,"version $v"])
    close(conn3)

end


function get_user( conn, user_id :: Integer )
    rs = DataFrame( execute( conn, "select user_id, email, password, description, created, expiry, is_temp from users where user_id='$user_id'"))[1,:]
    return User( rs.user_id, rs.email, rs.description, rs.password, rs.is_temp, rs.created, rs.expiry  )
end


=#
