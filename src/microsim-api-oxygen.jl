# CORS shit - see: https://github.com/OxygenFramework/Oxygen.jl#middleware
const CORS_HEADERS = [
    # "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

# https://juliaweb.github.io/HTTP.jl/stable/examples/#Cors-Server
function CorsMiddleware(handler)
    return function(req::HTTP.Request)
        @debug "CORS middleware"
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
    @debug uid
    ss = Symbol( subsys )
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    return json((; uid=user.user_id, runid=runrec.run_id, params=runrec.params[ss]))
end

@swagger"""
Set parameters for the given model/edition/subsys. Send a json representation of the subsys as payload.
"""
@post "/params/set/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    qp =  queryparams(req)
    @info qp
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    @debug uid
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    errs = Dict()
    ss = Symbol( subsys )
    try
        T = typeof( runrec.params[ss])
        sys = json( req, T)
        @debug "set ; got sys as " sys
        errs = tvalidate( sys )
        @debug "set ; errs " errs
        if length(errs) == 0
            @debug "set params to " sys
            runrec.params[ss] = sys            
        end
    catch e
        errs = Dict( "parse-exception"=>e)
    end
    save_run( runrec )
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[ss], errors = errs, output_is_cached=runrec.output_is_cached )
end

@get "/params/helppage/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    return html("<p>A helppage</p>")
end

@swagger"""
validates data but makes no attempt to load it or make things consistent
return uid, a dict of errs - 0 length if zero errors
"""
@post "/params/validate/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    ss = Symbol( subsys )
    T = typeof( runrec.params[ss])
    @debug "validate " T
    @debug string(req.body)
    errs = try
        sys = json( req, T)
        @debug "validate " sys
        x = tvalidate( sys )
        @debug x
        x
    catch e
        Dict( "parse-exception"=>e)
    end
    @debug "validate errors = " errs
    return (;uid=user.user_id, errors = errs )
end

@swagger"""

Reset app parameters for the given subsys back to the defaults.

"""
@get "/params/initialise/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    ss = Symbol( subsys )
    load_params!( runrec; copy_user_id=DEFAULT_USER_ID, copy_run_id=DEFAULT_RUN_ID)
    save_run( runrec )
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[ss], errors = runrec.errors[ss], output_is_cached=runrec.output_is_cached )
end

"""

"""
function submit_run( uid::Int, model_name::String, edition::String )
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    errs = Dict()
    no_errors, anyerrs = has_no_errors( runrec )
    @info no_errors anyerrs
    if no_errors # return bool and list of errors
        @info "setting state to 'queued'/Q"
        state = "queued"
        if runrec.output_is_cached
            @info "output_is_cached; set states to 'D'/displayed"
            state = "completed"
            change_run_qstate!( runrec; qstatus='D', output_is_cached=true )
        else
            @info "! output_is_cached; set states to 'Q'/queued"
            change_run_qstate!( runrec; qstatus='Q', output_is_cached=false )
        end
        update_progress( runrec.user_id, runrec.model_name, runrec.model_edition,
                        runrec.run_id,
                        Progress( BASE_UUID, "queued", -99, -99, -99, -99 ))
        # despite the name, this creates a new run
        runrec = get_run( user.user_id, runrec.model_name, runrec.model_edition, 'E', runrec.run_id )
    else
        errs = runrec.errors # FIXME poss > 1 record here
    end
    return (;uid=user.user_id, runid=runrec.run_id, errors=errs, output_is_cached=runrec.output_is_cached )
end

@swagger"""
Submit the active run.
if output_is_cached ....
return a named tuple with ( uid::Int, runid::Int, errors::Dict, output_is_cached::Bool )
"""
@get "/run/submit/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
    uid = getq(Int, req, "uid")
    return submit_run( uid, model_name, edition )
end

@swagger"""
return progress as an array (poss 0 length) of named tuples
"""
@get "/run/monitor/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, 'X', nothing )
    if ! isnothing(runrec)
        return json( get_run_progress( runrec ))
    else
        return json( msg="no_run")
    end
end

@swagger"""
THIS CURRENTLY DOES NOTHING
"""
@get "/run/abort/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, 'X', nothing )
end

function get_phunpack(
    runrec :: Run )
    outkey = OutputKey( "phunpack", "zip")
    item = runrec.output[outkey]
    zip_bytes = read(item.data)
    filename = "phunpack-$(runrec.model_name)-$(runrec.model_edition)-$(runrec.run_id).zip"
    return HTTP.Response(
        200,
        [
            "Content-Type"        => "application/zip",
            "Content-Disposition" => "attachment; filename=\"$filename\""
        ],
        body = zip_bytes
    )
end

@swagger"""
Retrieve a single item. Note phunpack treated seperately.
"""
@get "/output/fetch/{model_name}/{edition}/{format}/{item}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    format::String,
    item::String )
    uid = getq(Int, req,"uid")
    @debug uid format item
    user, runrec = handle_middle( uid, model_name, edition, 'D', nothing )
    if isnothing( runrec )
        return json( msg="no_run")
    end
    # special handling for phunpack
    if item == "phunpack" && format == "zip"
        return get_phunpack( runrec )
    end
    outkey = OutputKey( item, format )
    # @debug keys(runrec.output)
    if ! haskey( runrec.output, outkey )
        message = "Unable to find $item in format $format for $model_name/$edition runid=$(runrec.run_id)"
        @debug message
        return HTTP.Response( 404; body=message )
    end
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
