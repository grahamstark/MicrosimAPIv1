function tohtml( d :: DataFrame )
    io = IOBuffer()
    pretty_table( io, d; backend=:html, stand_alone=true )
    return String(take!(io))
end

"""
really just for testing: {} isn't  parsed back by json3 to a dict, so ...
"""
function to_dict(s)::Dict
    @show s
    #s = string(s)
    #@show s
    return if s == "{}" || length(s) == 0
        Dict()
    else
        JSON.parse(s,Dict)
    end
end

"""
Returns the base type of a variable some parameterised type reparameterised with `newtype`.

e.g if you have: 
    struct A{T}
        a :: T
    end
    x = A{Any}("xxx")

then:
    retype(x,Float64) -> A{Float64}
    Claude did this .. Obscure but useful for the API

"""
function retype(a, newtype::Type)::Type
    T = Base.typename(typeof(a)).wrapper
    return T{newtype}
end

abstract type Subsys end

"""
Simple min/max validation of a struct, using StructUtils annotations.
return - dict with an entry for each error
"""
function tvalidate(x)::Dict
    @argcheck isstructtype(typeof(x))
    T = typeof( x )
    tags = ftags( DefStyle(), T )
    vnames = fieldnames(T)
    n = length(vnames)
    @assert n == length(tags)
    d = Dict() # {String,NamedTuple}()
    for i in 1:n
        vname = vnames[i]
        v = getproperty(x, vname )
        tag = tags[i]
        agroup = Base.get( tag, :agroup, nothing )
        label = tag.label
        is_array = ! isnothing( agroup )
        datatype = typeof( v )
        if is_array
            label = "$(agroup): $label"
            datatype = eltype( v )
        end
        if datatype <: Number
            minv = Base.get( tag, :min, typemin(datatype))
            maxv = Base.get( tag, :max, typemax(datatype))
            sname = string(vname)
            if is_array
                for i in eachindex(v)
                    if v[i] < minv
                        if ! Base.haskey( d, sname )
                            d[sname]=[]
                        end
                        push!(d[sname], (; minv, value=v[i], label, index=i, error="below minimum" ))
                    elseif v[i] > maxv
                        if ! Base.haskey( d, sname )
                            d[sname]=[]
                        end
                        push!( d[sname], (; maxv, value=v[i], label, index=i, error="above maximum" ))
                    end
                end
            else
                if v < minv
                    d[sname] = (; minv, value=v, label, error="below minimum" )
                elseif v > maxv
                    d[sname] = (; maxv, value=v, label, error="above maximum" )
                end
            end
        end
    end #
    return d
end

"""
Make a struct annotated with StructUtils.@tag into a table.

"""
function struct_to_labels( x )
    @argcheck isstructtype(typeof(x))
    T = typeof( x )
    tags = ftags( DefStyle(), T )
    vnames = fieldnames(T)
    n = length(vnames)
    @assert n == length(tags)
    d = DataFrame(
        varname = fill(Symbol(""),n),
        datatype = fill("",n),
        label = fill("",n),
        default = fill("",n),
        minv = fill("",n),
        maxv = fill("",n),
        unit = fill("",n),
        is_array = fill( "N",n),
        precision = fill("-", n ))
    for i in 1:n
        vname = vnames[i]
        v = getproperty(x, vname )
        tag = tags[i]
        r = d[i,:]
        r.varname = vname
        agroup = Base.get( tag, :agroup, nothing )
        label = tag.label
        is_array = ! isnothing( agroup )
        datatype = typeof( v )
        val = "$v"
        if is_array
            label = "$(agroup): $label"
            r.is_array = "Y"
            datatype = eltype( v )
            val = "[" * join( string.(v),", ") *"]"
        end
        r.datatype = "$datatype"
        r.label = label
        r.unit = Base.get( tag, :unit, "" )
        r.default = val
        r.minv = string(Base.get( tag, :min, "No Minimum" ))
        r.maxv = string(Base.get( tag, :max, "No Maximum" ))
        r.precision = if datatype <: AbstractFloat
            string(Base.get( tag, :prec, 2 ))
        elseif datatype <: Number
            "0"
        else
            "-"
        end
    end #
    return tohtml( d )
end

function structname( thestruct )
    @argcheck isstructtype( typeof(thestruct))
    return match( r"(.*\.)?(.*?)({|$).*", string(typeof(thestruct)))[2]
end

function getq( T::DataType, req :: HTTP.Request, key :: String )
    qp =  queryparams(req)
    @show qp
    vs = Base.get(qp,key,nothing)
    v = if ! isnothing( vs )
        parse( T, vs )
    else
        nothing
    end
end

# TODO something to create and load db from StructUtils


"""
<fieldset class='col border rounded-2 m-1 p-2'>
    <legend>National Insurance</legend>
    <input type="hidden" id="ni-n" name="ni-n" value=""/>
    <table class="table table-sm table-striped">
        <caption>Rates in %, bands in &pound;s pw</caption>
        <thead>
            <tr>
                <th>Rate (%)</th>
                <th>Band (£pw)</th>
                <th></th>
                <th></th>
            </tr>
        </thead>
        <tbody id='ni-rows'>
        </tbody>
    </table>
</fieldset>
"""

"""
<div class="col">
    <label for='scottish_child_payment' class='form-label'>Scottish Child Payment £pw</label>
    <input id='scottish_child_payment' type='number' name="scottish_child_payment" min='0' max='400' value='' step='0.01' size="10" class='form-control w-50'/>
</div>
"""

#=
Claude did this bit ... Logger that writes without flushing.
=#

struct FlushingLogger <: AbstractLogger
    logger::AbstractLogger
    io::IO
end

Logging.min_enabled_level(fl::FlushingLogger) = Logging.min_enabled_level(fl.logger)
Logging.shouldlog(fl::FlushingLogger, args...) = Logging.shouldlog(fl.logger, args...)
Logging.catch_exceptions(fl::FlushingLogger) = Logging.catch_exceptions(fl.logger)

function Logging.handle_message(fl::FlushingLogger, args...; kwargs...)
    Logging.handle_message(fl.logger, args...; kwargs...)
    flush(fl.io)
end
