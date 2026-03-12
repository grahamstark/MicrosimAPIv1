using LibPQ, DataFrames,ConcurrentUtilities.Pools,Dates,Random

function makeconn()::LibPQ.Connection
    return LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")
end

function makeps( statement )
    conn = makeconn()
    ps = prepare(conn, statement )
end

function create_ps( statement )
    f = makeps( statement )
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
    username :: String
    email    :: String
    password :: String
    is_temp  :: Bool
    created :: DateTime
end

function get_user( conn, username :: String )
    rs = DataFrame( execute( conn, "select username, email, password, created, is_temp from users where username='$username'"))[1,:]
    return User( rs.username, rs.email, rs.password, rs.is_temp, rs.created )
end

function create_temp_user()::User
    conn = makeconn()
    username = randstring(30)
    execute( conn, "insert into users( username, email, password, created, is_temp ) values( '$username', '', '', now(), true )" )
    rs = DataFrame( execute( conn, "select username, email, password, created, is_temp from users where username='$username'"))[1,:]
    u = get_user( conn, username )
    close(conn)
    return u
end

function
