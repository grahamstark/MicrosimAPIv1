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

@get "/info/params-description/{model_name}/{edition}/{subsys}" list_params
# synonym
@get "/params/info/{model_name}/{edition}/{subsys}" list_params

@get "/params/get/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    return runrec.params[subsys]
end

@get "/params/set/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    errors = "XXX"
    params = "XXX"
    save_params( runrec, "XXX", params, errors )
end

@get "/params/helppage/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String)
end

@get "/params/validate/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )

end

@get "/params/describe/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing})
end

@get "/params/subsys/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing},
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/params/initialise/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::Union{String,Nothing},
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
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

@get "/output/items/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String )
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
    item::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end
