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
    df = get_available_models()[1]
    return tohtml( df )
end

@swagger"""

TODO pass preferred format

"""
@get "/info/available-editions/{model_name}" function(
    req::HTTP.Request,
    model_name::String )

    df = get_available_editions( model_name )[1]
    return tohtml( df[!, 2:end] )
end

@swagger"""
TODO pass preferred format
"""
@get "/info/available-subsystems/{model_name}/{edition}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    df = get_available_subsystems( model_name, edition )[1]
    return tohtml( df[!,1:3] )
end

@swagger"""
TODO pass preferred format
"""
function list_params(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing})
    # if ... or somewhere in db
    df = get_parameter_descriptions( model_name, edition, subsys )[1]
    @assert size(df)[1] == 1 # TODO return error
    return df[1,:info]
end

function list_outputs(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    return tohtml(get_output_descriptions( model_name )[1])
end

# synonyms
@swagger"""
TODO pass preferred format html/json
"""
@get "/info/params-description/{model_name}/{edition}/{subsys}" list_params
@get "/params/info/{model_name}/{edition}/{subsys}" list_params
# synonyms
@swagger"""
TODO pass preferred format html/json
"""
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
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[subsys], errs = runrec.errors[subsys], output_is_cached=runrec.output_is_cached )
end

@swagger"""
Submit the active run.
if output_is_cached ....
"""
@get "/run/submit/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    errs = Dict()
    if has_no_errors( runrec )
        state = "queued"
        if run.output_is_cached
            state = "completed"
            change_run_state!( runrec; qstatus='C', output_in_sync=true )
        else
            change_run_state!( runrec; qstatus='Q', output_in_sync=false )
        end
        update_progress( runrec.user_id, runrec.model_name, runrec.edition,
                        runrec.run_id,
                        Progress( BASE_UUID, state, -99, -99, -99, -99 ))
    else
        errs = runrec.errs # FIXME poss > 1 record here
    end
    return (;uid=user.user_id, runid=runrec.run_id, errs=errs, output_is_cached=runrec.output_is_cached )
end

@swagger"""
return progress as an array (poss 0 length) of named tuples
"""
@get "/run/monitor/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    return json( get_run_progress( run))
end

@swagger"""
THIS CURRENTLY DOES NOTHING
"""
@get "/run/abort/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@swagger"""
Retrieve a complete zipfile
"""
@get "/output/phunpack/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    uid = getq(Int, req, "uid")
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
