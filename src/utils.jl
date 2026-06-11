function tohtml( d :: DataFrame )
    io = IOBuffer()
    pretty_table( io, d; backend=:html, stand_alone=true )
    return String(take!(io))
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
        is_array = fill( "N",n))
    for i in 1:n
        vname = vnames[i]
        v = getproperty(x, vname )
        tag = tags[i]
        r = d[i,:]
        r.varname = vname
        agroup = get( tag, :agroup, nothing )
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
        r.unit = get( tag, :unit, "" )
        r.default = val
        r.minv = string(get( tag, :min, "No Minimum" ))
        r.maxv = string(get( tag, :max, "No Maximum" ))
    end #
    return tohtml( d )
end

function structname( thestruct )
    @argcheck isstructtype( typeof(thestruct))
    return match( r"(.*?)({|$).*", string(typeof(thestruct)))[1]
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
