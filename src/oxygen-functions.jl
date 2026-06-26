# CORS shit - see: https://github.com/OxygenFramework/Oxygen.jl#middleware
const CORS_HEADERS = [
    # "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

# https://juliaweb.github.io/HTTP.jl/stable/examples/#Cors-Server
function CorsMiddleware(handler)
    return function(req::HTTP.Request)
        println("CORS middleware")
        # determine if this is a pre-flight request from the browser
        if HTTP.method(req)=="OPTIONS"
            return HTTP.Response(200, CORS_HEADERS)
        else
            return handler(req) # passes the request to the AuthMiddleware
        end
    end
end



@get "/info/available-models" function(
    req::HTTP.Request )
    df = get_available_models()
    return tohtml( df )
end

@get "/info/available-editions/{model_name}" function(
    req::HTTP.Request,
    model_name::String )
    df = get_available_editions( model_name )
    return tohtml( df[!, 2:end] )
end

@get "/info/available-subsystems/{model_name}/{edition}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    df = get_available_subsystems( model_name, edition )
    return tohtml( df[!,1:3] )
end

function list_params(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing})
    # if ... or somewhere in db
    df = get_parameter_descriptions( model_name, edition, subsys )
    @assert size(df)[1] == 1 # TODO return error
    return df[1,:info]
end

function list_outputs(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    return tohtml(get_output_descriptions( model_name ))
end

# synonyms
@get "/info/params-description/{model_name}/{edition}/{subsys}" list_params
@get "/params/info/{model_name}/{edition}/{subsys}" list_params
# synonyms
@get "/info/available-outputs/{model_name}/{edition}" list_outputs
@get "/output/info/{model_name}/{edition}" list_outputs

@get "/params/get/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String )
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    @info uid
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    return json((; uid=user.user_id, runid=runrec.run_id, params=runrec.params[subsys]))
end

function get_sys(req::HTTP.Request,
                 subsys::String)::Subsys
    T = eval(Symbol(subsys)){Float64}
    @info " got type as " T
    @info req
    sys = json( req, T)
    @info sys
    return sys
end

@post "/params/set/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    qp =  queryparams(req)
    @info qp
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    @info uid
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    errs = Dict()
    try
        sys = get_sys( req, subsys )
        @info "set ; got sys as " sys
        errs = tvalidate( sys )
        @info "set ; errs " errs
        if length(errs) == 0
            @info "set params to " sys
            jsys = JSON3.write( sys )
            @info jsys
            runrec.params[subsys] = jsys
            @info "saving "
            save_params( runrec, subsys, jsys, JSON3.write( errs ))
            @info "saved OK"
        end
    catch e
        errs = Dict( "parse-exception"=>e)
    end
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[subsys], errs = errs, output_is_cached=runrec.output_is_cached )
end

@get "/params/helppage/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    return html("<p>A helppage</p>")
end

"""
validates data but makes no attempt to load it or make things consistent
return uid, a dict of errs - 0 length if zero errors
"""


@post "/params/validate/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    @info string(req.body)
    errs = try
        sys = get_sys( req, subsys )
        tvalidate( sys )
    catch e
        Dict( "parse-exception"=>e)
    end
    return (;uid=user.user_id, errs = errs )
end


@get "/params/initialise/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )

    load_params!( runrec; copy_user_id=DEFAULT_USER_ID, copy_run_id=DEFAULT_RUN_ID)

    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[subsys], errs = runrec.errors[subsys], output_is_cached=run.output_is_cached )
end

function submit_run( run :: Run )
   @info "Submit!"
end

@get "/run/submit/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    if has_no_errors( runrec )
        h = make_param_hash( runrec.user_id, runrec.model_name, runrec.model_edition, runrec.run_id )
        state = "queued"
        if run.output_is_cached
            state = "completed"
            change_run_state!( runrec; qstatus='C', output_in_sync=true )
        else
            submit_run( runrec )
        end
        update_progress( runrec.user_id, runrec.model_name, runrec.edition,
                        runrec.run_id,
                        Progress( BASE_UUID, state, -99, -99, -99, -99 ))
        return json( )
    else

    end
    # 1 check no parameter errors
end

@get "/run/monitor/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/run/abort/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/output/phunpack/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/output/fetch/{model_name}/{edition}/{format}/{item}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    format::String,
    item::String)
    uid = getq(Int, req,"uid")
    @info uid format item
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    outkey = OutputKey( item, format )
    # @info keys(runrec.output)
    item = runrec.output[outkey]
    # fixme more idiomatic
    return if format == "svg"
        Oxygen.xml( item.data )
    elseif format == "html"
        Oxygen.html( item.data )
    else
        Oxygen.json( item.data )
    end
end
