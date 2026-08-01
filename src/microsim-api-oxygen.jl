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

function parse_and_check_params( runrec :: Run, req :: HTTP.Request, ss :: Symbol )::Tuple
    errs = Dict()
    T = typeof( runrec.params[ss])
    errors, system = try
        sys = json( req, T)
        errs = tvalidate( sys )
        errs, sys
    catch e
        Dict( "parse-exception"=>e), nothing
    end
    return errors, system
end

@swagger"""
Set parameters for the given model/edition/subsys. Send a json representation of the subsys as payload.
"""
@post "/params/set/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    qp = queryparams(req)
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    ss = Symbol( subsys )
    errs, params = parse_and_check_params( runrec, req, ss )
    if(length( errs ) == 0) && (! isnothing(params))
        runrec.params[ss] = params
        save_run!( runrec )
    end
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[ss], errors = errs, output_is_cached=runrec.output_is_cached )
end

@swagger"""

TODO - not implemented yet.

"""
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
    errs, _ = parse_and_check_params( runrec, req, ss )
    # .. but don't save them
    return (;uid=user.user_id, runid=runrec.run_id, errors = errs )
end

@swagger"""

Reset app parameters for the given subsys back to the defaults.

"""
@get "/params/initialise/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing}=nothing)
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    ss = Symbol( subsys )
    load_params!( runrec; copy_user_id=DEFAULT_USER_ID, copy_run_id=DEFAULT_RUN_ID)
    save_run!( runrec )
    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[ss], errors = Dict(), output_is_cached=runrec.output_is_cached )
end

@swagger"""
Submit the active run.
if output_is_cached ....
return a named tuple with ( uid::Int, runid::Int, errors::Dict, output_is_cached::Bool )
"""
@post "/run/submit/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{Nothing,String} )
    uid = getq(Int, req, "uid")
    user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    errs = Dict()
    # handle if we're submitting params as well as requesting a run
    if ! isnothing( subsys )
        ss = Symbol( subsys )
        errs, params = parse_and_check_params( runrec, req, ss )
        if length( errs ) == 0 # return bool and list of errors
            runrec.params[ss] = params
        end
    end
    if length( errs ) == 0
        save_run!( runrec )
        @info "setting state to 'queued'/Q"
        state = "queued"
        if ! runrec.output_is_cached
            @info "! output_is_cached; set states to 'Q'/queued"
            change_run_qstate!( runrec; qstatus='Q', output_is_cached=false )
            # despite the name, this creates a new run as a copy of the run that's just been queued
            runrec = get_run( user.user_id, runrec.model_name, runrec.model_edition, 'E', runrec.run_id )
        else
            @info "output_is_cached; set states to 'D'/displayed"
            state = "completed"
            # toggle so there's only one displayed run ever
            set_run_to_displayed!( runrec )
        end
        update_progress(
            runrec.user_id,
            runrec.model_name,
            runrec.model_edition,
            runrec.run_id,                                                                                                                                                                                                                                                          Progress( BASE_UUID, state, -99, -99, -99, -99 ))
    end
    return (;
            uid=user.user_id,
            runid=runrec.run_id,
            errors=errs,
            output_is_cached=runrec.output_is_cached,
            params=runrec.params[ss] )
end

@swagger"""
return uid=uid, runid, output_is_cached, qstatus, progress
   progress as an array (poss 0 length) of named tuples
"""
@get "/run/monitor/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
    uid = getq(Int, req, "uid")
    rid = getq(Int, req, "rid")
    # any run in executing state?
    runrec = retrieve_specific_run( uid, model_name, edition, rid )
    if ! isnothing(runrec) # then extract
        return json( (; uid=uid, runid=rid, output_is_cached=runrec.output_is_cached, qstatus=runrec.qstatus, progress=get_run_progress( runrec )))
    else
        return json( (;msg="no_run"))
    end
end

@swagger"""
FIXME THIS CURRENTLY DOES NOTHING
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
    # look for displayed run
    user, runrec = handle_middle( uid, model_name, edition, 'D', nothing )
    if isnothing( runrec )
        # ... but fall back on finding edited run
        user, runrec = handle_middle( uid, model_name, edition, 'E', nothing )
    end
    if runrec.output_is_cached
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
    else
        return json( (;msg="no output"))
    end
end
