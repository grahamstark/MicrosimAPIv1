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
    subsys::String,
    uid::Union{Nothing,Int}=nothing )
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    @show uid
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
    subsys::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    qp =  queryparams(req)
    @show qp
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    @show uid
    user, runrec = handle_middle( uid, model_name, edition, nothing )

    return (;uid=user.user_id, runid=runrec.run_id, params=runrec.params[subsys] )
end

@get "/params/helppage/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
end

@post "/params/validate/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
    uid = getq(Int, req, "uid") # ?? shouldn't be needed
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    @info string(req.body)
    return try
        sys = get_sys( req, subsys )
        json(tvalidate( sys ))
    catch e
        json( Dict( "parse-exception"=>e))
    end
end

@post "/params/initialise/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/run/submit/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
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
    @show uid format item
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    outkey = OutputKey( item, format )
    # @show keys(runrec.output)
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
