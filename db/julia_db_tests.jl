using LibPQ, DataFrames,ConcurrentUtilities.Pools,Dates,Random

function makeconn()::LibPQ.Connection
    return LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")
end

function makeps( statement )
    conn = makeconn()
    ps = prepare(conn, statement )
end

const CON_POOL = Pool{LibPQ.Connection}(10)
const PS_POOL = Pool{LibPQ.Statement}(20)

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

struct User
    user_id :: Int
    email    :: String
    password :: String
    description :: String
    is_temp  :: Bool
    created :: DateTime
    expiry  :: DateTime
end

function get_user( conn, user_id :: Integer )
    rs = DataFrame( execute( conn, "select user_id, email, password, description, created, expiry, is_temp from users where user_id='$user_id'"))[1,:]
    return User( rs.user_id, rs.email, rs.description, rs.password, rs.is_temp, rs.created, rs.expiry  )
end


user_create = makeps(
    """
    insert into users( user_id, email, password, description, created, expiry, is_temp ) values( \$1, \$2, \$3, \$4, now(), now()+'interval 1 day', \$5 )
    """
    )



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
run_insert = makeps(
    """
       insert into runs( user_id, model_name, model_version, run_id, run_name, submission, qstatus, is_displayed, is_edited ) values
           ( \$1, \$2 ,\$3 ,\$4, \$5, now(), \$6, \$7, \$8 )
       on conflict( user_id, model_name, model_version, run_id )
       do update
           set qstatus=\$9, is_displayed=\$10, is_edited=\$11
       """)

run_state_insert = makeps(
    """
    insert into run_state( user_id, model_name, model_version, run_id, thread_no, phase, completed, todo, timer )
    values(\$1, \$2,\$3, \$4, \$5, \$6, \$7, \$8, now() ) on conflict( user_id, model_name, model_version, run_id, thread_no ) do
        update set phase=\$9, completed=\$10, todo=\$11, timer=now();
    """)

run_params = [2,"scotben","0.17",1, "some uuid","E",false,true,"X",false,true]
execute( run_insert, run_params )
run_state_params = [2,"scotben","0.17",1, 2,"running",999,10_000,"running",2000,10_000]
execute( run_state_insert, run_state_params )


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


function t50k()
    @time for i in 1:50_00
        u=create_temp_user()
        if (i % 2000)==0
            println(u.user_id)
        end
    end
end

function create_run()

    conn = makeconn()
    try
    select max(run_id)+1 from runs where user_id=? and model_name=? and model_version=?;

end


