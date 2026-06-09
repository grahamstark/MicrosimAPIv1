@get "/params/list-available/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
end

@get "/params/get/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/params/set/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )

end

@get "/params/helppage/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
end

@get "/params/validate/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/params/describe/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
end

@get "/params/subsys/{model_name}/{edition}/{subsys}" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    subsys::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    user, runrec = handle_middle( uid, model_name, edition, nothing )
end

@get "/params/initialise/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
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

@get "/params/info/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String)
    # if ... or somewhere in db
    return if edition == "simple-2026a"
        Oxygen.html(struct_to_labels(DEFAULT_SIMPLE_PARAMS))
    elseif edition == ""
        Oxygen.html(struct_to_labels(DEFAULT_SIMPLE_PARAMS))
    end
end
