

import MicrosimAPIv1 as msa

# julia> sj = JSON3.write(msa.DEFAULT_MINI_PARAMS)
const JPS = """
{
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"child_benefit\":27.05,
    \"pension\":241.3,
    \"scottish_child_payment\":28.2,
    \"scp_age\":15,
    \"uc_single\":424.9,
    \"uc_taper\":55.0
}
"""
const JPS_CHANGED = """
{
    \"taxrates\":[19.0,21.0,22.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"child_benefit\":27.05,
    \"pension\":241.3,
    \"scottish_child_payment\":28.2,
    \"scp_age\":15,
    \"uc_single\":424.9,
    \"uc_taper\":55.0
}
"""

const JPS_OUT_OF_RANGE = """
{
    \"taxrates\":[119.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[-3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"child_benefit\":27.05,
    \"pension\":241.3,
    \"scottish_child_payment\":28.2,
    \"scp_age\":15,
    \"uc_single\":424.9,
    \"uc_taper\":55.0
}
"""

const UBIS = """
{
    \"abolished\":false,
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"abolish_uc\":true,
    \"abolish_sickness_bens\":false,
    \"abolish_jsa_esa\":true,
    \"abolish_pensions\":true,
    \"abolish_housing\":true,
    \"abolish_others\":true,
    \"ubi_as_mt_income\":true,
    \"ubi_taxable\":false,
    \"adult_amount\":4800.0,
    \"child_amount\":3000.0,
    \"universal_pension\":8780.0,
    \"adult_age\":17,
    \"retirement_age\":66
}

"""

const UBIS_OUT_OF_RANGE = """
{
    \"abolished\":false,
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"abolish_uc\":true,
    \"abolish_sickness_bens\":false,
    \"abolish_jsa_esa\":true,
    \"abolish_pensions\":true,
    \"abolish_housing\":true,
    \"abolish_others\":true,
    \"ubi_as_mt_income\":true,
    \"ubi_taxable\":false,
    \"adult_amount\":4800.0,
    \"child_amount\":3000.0,
    \"universal_pension\":8780.0,
    \"adult_age\":117,
    \"retirement_age\":-1
}

"""
const UBIS_CHANGED = """
{
    \"abolished\":false,
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"abolish_uc\":true,
    \"abolish_sickness_bens\":false,
    \"abolish_jsa_esa\":true,
    \"abolish_pensions\":true,
    \"abolish_housing\":true,
    \"abolish_others\":true,
    \"ubi_as_mt_income\":true,
    \"ubi_taxable\":false,
    \"adult_amount\":4800.0,
    \"child_amount\":3000.0,
    \"universal_pension\":8780.0,
    \"adult_age\":14,
    \"retirement_age\":70
}
"""

const GOOD_PARAMS = Dict( "UBIParams"=>UBIS, "SimpleParams"=>JPS)
const OUT_OF_RANGE_PARAMS = Dict( "UBIParams"=>UBIS_OUT_OF_RANGE, "SimpleParams"=>JPS_OUT_OF_RANGE)
const CHANGE_PARAMS = Dict( "UBIParams"=>UBIS_CHANGED, "SimpleParams"=>JPS_CHANGED)
const FAIL_PARAMS = Dict( "UBIParams"=>"XSAxx:1", "SimpleParams"=>"Junk:22")
const ALL_PARAMS = [(;data=GOOD_PARAMS,nerrs=0), (;data=OUT_OF_RANGE_PARAMS,nerrs=2), (;data=FAIL_PARAMS,nerrs=1), (;data=CHANGE_PARAMS,nerrs=0)]

@testset "JSON Tests" begin
    p1 = JSON3.read( JPS, msa.SimpleParams{Float64})
    # doesn't work because of the array see: https://discourse.julialang.org/t/define-equality-for-struct-by-checking-all-fields/121325
    # @test p1 == msa.DEFAULT_MINI_PARAMS["SimpleParams"]
    p2 = JSON3.read( UBIS, msa.UBIParams{Float64})
    # @test p2 == msa.DEFAULT_MINI_PARAMS["UBIParams"]
end

# from oxygen's testcases
@testset "formdata" begin
    req = Response("message=hello world&value=3")
    data = formdata(req)
    @test data["message"] == "hello world"
    @test data["value"] == "3"
end


@testset "valid model name returns 200" begin
    req = HTTP.Request("GET", "/info/available-models/")
    resp = internalrequest(req)
    @test resp.status == 200
    @show resp.body
    @test occursin("text/html", HTTP.header(resp, "Content-Type"))
end

@testset "available editions" begin
    df = get_available_models()
    n = 0
    for d in eachrow(df)
        req = HTTP.Request("GET", "/info/available-editions/$(d.model_name)")
        resp = internalrequest(req)
        @test resp.status == 200
        @show resp.body
        @test occursin("text/html", HTTP.header(resp, "Content-Type"))
        n += 1
    end
    @test n > 0
end

@testset "available subsystems" begin
    ms = get_available_models()
    n = 0
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ed = get_available_subsystems( e.model_name, e.model_edition )
            req = HTTP.Request("GET", "/info/available-subsystems/$(e.model_name)/$(e.model_edition)")
            resp = internalrequest(req)
            @test resp.status == 200
            @show resp.body
            @test occursin("text/html", HTTP.header(resp, "Content-Type"))
            n += 1
        end
    end
    @test n > 0
end

@testset "List Params" begin
    ms = get_available_models()
    n = 0
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ss = get_available_subsystems( e.model_name, e.model_edition )
            for s in eachrow(ss)
                req = HTTP.Request("GET", "/info/params-description/$(s.model_name)/$(s.model_edition)/$(s.subsys)")
                resp = internalrequest(req)
                @test resp.status == 200
                @show resp.body
                @test occursin("text/html", HTTP.header(resp, "Content-Type"))
                n += 1
            end
        end
    end
    @test n > 0
end

@testset "List Outputs" begin
    ms = get_available_models()
    n = 0
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
                req = HTTP.Request("GET", "/info/available-outputs/$(e.model_name)/$(e.model_edition)/")
                resp = internalrequest(req)
                @test resp.status == 200
                @show resp.body
                @test occursin("text/html", HTTP.header(resp, "Content-Type"))
                n += 1
        end
    end
    @test n > 0
end
# julia>

@testset "Get Params" begin
    ms = get_available_models()
    n = 0
    global uid # share this user once created
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ss = get_available_subsystems( e.model_name, e.model_edition )
            for s in eachrow(ss)
                req = HTTP.Request("GET", "/params/get/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)")
                resp = internalrequest(req)
                @test resp.status == 200
                @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                jp = json(resp)
                @show jp["uid"]
                uid = jp["uid"]
                rec = JSON3.read( jp["params"], eval( Symbol(s.subsys)))
                @show rec
                n += 1
            end
        end
    end
    @test n > 0
end


@testset "Validate Params" begin
    ms = get_available_models()
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ss = get_available_subsystems( e.model_name, e.model_edition )
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    req = HTTP.Request("POST", "/params/validate/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    resp = internalrequest(req)
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    errs = jp["errs"]
                    @show errs
                    @test length( errs ) == p.nerrs
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Load Params" begin
    ms = get_available_models()
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ss = get_available_subsystems( e.model_name, e.model_edition )
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    req = HTTP.Request("POST", "/params/set/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    resp = internalrequest(req)
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    errs = jp["errs"]
                    @show errs
                    @show jp["params"]
                    @test length( errs ) == p.nerrs
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Initialise Params" begin
    ms = get_available_models()
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = get_available_editions( m.model_name )
        for e in eachrow( es )
            ss = get_available_subsystems( e.model_name, e.model_edition )
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    req = HTTP.Request("POST", "/params/set/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    resp = internalrequest(req)
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    errs = JSON3.read(string(jp["errs"]),Dict)
                    @show errs
                    @show jp["params"]
                    @test length( errs ) == p.nerrs
                    req2 = HTTP.Request("GET", "/params/initialise/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers )
                    resp2 = internalrequest(req2)
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP
                    jp2 = json(resp2)
                    errs2 = JSON3.read(jp2["errs"],Dict)
                    # params should always be reset to base, but in JSON
                    @test jp2["params"] == JSON3.write( DEFAULT_MINI_PARAMS[ s.subsys ])
                    uid2 = jp2["uid"] # set to the id of a temp user on 1st call, with user
                    @test uid2 == uid
                    @show errs2
                    @test length( errs2 ) == 0
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Submit Run" begin


end

@testset "Abort Run" begin


end

@testset "Monitor Run" begin


end

@testset "Output Fetch" begin


end

@teststet "Phunpack Search" begin

end
