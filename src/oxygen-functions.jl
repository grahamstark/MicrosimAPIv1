
#=

list outputs
progress
submit run
submit inputs
describe inputs
available models
available

=#

#=
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
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

function middle(req::HTTP.Request)
    user, runrec = handle_middle( user_id, model_name, edition, copy_from )

end

@get "/greet" function(req::HTTP.Request)
    middle( req )
    return "hello world!"
end
=#

@get "/run/{model_name}/{edition}/" function(
    req::HTTP.Request,
    model_name::String,
    edition::String,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing )
    user, runrec = handle_middle( uid, model_name, edition, nothing )
    return Oxygen.html( "<p>uid=$(user.user_id) runid=$(runrec.run_id)</p>")
end

@get "/div/{a}/{b}/"  function(
    request::HTTP.Request,
    b::Int,
    a::Int,
    q::Int=10,
    uid::Union{Nothing,Int}=nothing,
    runid::Union{Nothing,Int}=nothing)
    println( "uid=$uid")
    return q + Float64(b)/a
end

@get "/add/{a}/{b}" function( req :: HTTP.Request, a::Int, b::Int )
    return Oxygen.html( "<p>A=$(a + b)</p>")
end

# start the web server
serve()
