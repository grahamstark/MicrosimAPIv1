conn = LibPQ.Connection("dbname=microapi user=postgres host=/var/run/postgresql")

result = execute(conn, "SELECT * from users")

ps = prepare(conn, "select username from users where is_temp = \$1")

r2 = execute(ps,[true])
DataFrame(r2)

ins = prepare( conn, "insert into models values( \$1, \$2 )")

result = execute( ins, ["lanman", "Howards Model"])


vins = prepare( conn, "insert into model_versions values( \$1, \$2, \$3 )")


result = execute( vins, ["lanman", Decimal(0.1), "Howards Model"])
