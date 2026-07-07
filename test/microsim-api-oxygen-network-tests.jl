#=
Same tests as `microsim-api-oxygen-local-tests.jl` but with the locally configured
web service (via apache). Note we can use the versions packaged in MicrosimAPIv1
here. 
=#

import MicrosimAPIv1 as msa

const TEST_URL = "http://microapi-local/" 
# or http://localhost:LIVE_PORT|TEST_PORT

@testset "valid model name returns 200" begin
    resp = HTTP.request("GET", "$TEST_URL/info/available-models/")
    
    @test resp.status == 200
    @show resp.body
    @test occursin("text/html", HTTP.header(resp, "Content-Type"))
end

@testset "available editions" begin
    df = msa.get_avalable_models()[1]
    n = 0
    for d in eachrow(df)
        resp = HTTP.request("GET", "$TEST_URL/info/available-editions/$(d.model_name)")
        @test resp.status == 200
        @show resp.body
        @test occursin("text/html", HTTP.header(resp, "Content-Type"))
        n += 1
    end
    @test n > 0
end

@testset "available subsystems" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    for m in eachrow(ms)
        es = msa.msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ed = msa.get_avalable_subsystems( e.model_name, e.model_edition )
            resp = HTTP.request("GET", "$TEST_URL/info/available-subsystems/$(e.model_name)/$(e.model_edition)")
            @test resp.status == 200
            @show resp.body
            @test occursin("text/html", HTTP.header(resp, "Content-Type"))
            n += 1
        end
    end
    @test n > 0
end

@testset "List Params" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                resp = HTTP.request("GET", "$TEST_URL/info/params-description/$(s.model_name)/$(s.model_edition)/$(s.subsys)")
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
    ms = msa.get_avalable_models()[1]
    n = 0
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
                resp = HTTP.request("GET", "$TEST_URL/info/available-outputs/$(e.model_name)/$(e.model_edition)/")
                @test resp.status == 200
                @show resp.body
                @test occursin("text/html", HTTP.header(resp, "Content-Type"))
                n += 1
        end
    end
    @test n > 0
end
# julia>


# convoluted, but works - no real explanation why
jparse( jp, k, T::Type ) = JSON.parse( JSON.json(jp[k]), T )
# convoluted, but works - no real explanation why
jparse( jp, k, T::String ) = JSON.parse( JSON.json(jp[k]), eval( Symbol( T )))

@testset "Get Params" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    global uid # share this user once created
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                resp = HTTP.request("GET", "$TEST_URL/params/get/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)")
                @test resp.status == 200
                @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                jp = json(resp)
                @show jp["uid"]
                uid = jp["uid"]
                rec = jparse( jp, "params", s.subsys)
                @show rec
                n += 1
            end
        end
    end
    @test n > 0
end

@testset "Validate Params" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    resp = HTTP.request("POST", "$TEST_URL/params/validate/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    # errs = jp["errors"]
                    errs = jparse( jp, "errors", Dict )
                    @show errs
                    @show p.nerrs
                    @test length( errs ) == p.nerrs 
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Load Params" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    resp = HTTP.request("POST", "$TEST_URL/params/set/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    errs = jp["errors"]
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
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                for p in ALL_PARAMS # each set of parameters either validates, fails with 2 range errors or fails with a parse error, so...
                    resp = HTTP.request("POST", "$TEST_URL/params/set/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    @show resp
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    jp = json(resp)
                    uid = jp["uid"] # set to the id of a temp user on 1st call, with user saved in db from that point on
                    @show jp["params"]
                    req2 = HTTP.Request("GET", "$TEST_URL/params/initialise/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers )
                    resp2 = internalrequest(req2)
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP
                    jp2 = json(resp)
                    uid2 = jp2["uid"] # set to the id of a temp user on 1st call, with user
                    @test uid2 == uid
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Submit Run" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                for p in ALL_PARAMS[1:2] # just the good ones..
                    resp = HTTP.request("POST", "$TEST_URL/params/set/$(s.model_name)/$(s.model_edition)/$(s.subsys)/?uid=$(uid)", headers,  p.data[s.subsys])
                    resp = HTTP.request("GET", "$TEST_URL/run/submit/$(s.model_name)/$(s.model_edition)/?uid=$(uid)", headers )
                    @show resp
                    jp = json( resp )
                    @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                    @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                    @show jp
                    @test jp["output_is_cached"]
                    n += 1
                end
            end
        end
    end
    @test n > 0
end

@testset "Abort Run" begin
# FIXME not implemented
end

@testset "Monitor Run" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        for e in eachrow( es )
            ss = msa.get_avalable_subsystems( e.model_name, e.model_edition )[1]
            for s in eachrow(ss)
                resp = HTTP.request("GET", "$TEST_URL/run/monitor/$(s.model_name)/$(s.model_edition)/?uid=$(uid)", headers )
                @show resp
                @test resp.status == 200 # even a parse error shouldn't raise an HTTP error
                @test occursin("application/json", HTTP.header(resp, "Content-Type"))
                n += 1
            end
        end
    end
    @test n > 0
end

@testset "Output Fetch" begin
    ms = msa.get_avalable_models()[1]
    n = 0
    headers = []
    global uid
    for m in eachrow(ms)
        es = msa.get_avalable_editions( m.model_name )[1]
        outputs = get_output_descriptions( m.model_name )[1]
        for e in eachrow( es )
            for o in eachrow( outputs )
                resp = HTTP.request("GET", "$TEST_URL/output/fetch/$(e.model_name)/$(e.model_edition)/$(o.datatype)/$(o.item)/?uid=$(uid)", headers )
                @test resp.status == 200
                @show resp
                n += 1
            end
        end
    end
    @test n > 0
end