
StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{ParamsAndId}) = StructTypes.Struct()
StructTypes.StructType(::Type{Progress})  = StructTypes.Struct()

function paramsfrompayload( )::ParamsAndId
    @info  "paramsfrompayload entered:"
    @info rawpayload()
    pars = JSON3.read( rawpayload(), ParamsAndId{Float64}) # SimpleParams{Float64} ) #ParamsAndId{Float64})
    return pars
end

function validate_value!( d::Dict, name::String, v :: Real ; min=0, max=1000 )
    if (v < min) || (v > max)
        d[name] = "$(name) is outside the range $(min) - $(max)"
    end
    d
end

function validate_ratebands!( errs::Dict, name::String, rates::Vector, bands::Vector)
    nr = length( rates )
    nb = length( bands )
    if nr - nb > 1
        errs["$(name)rates"] = "Length of $name rates and bands should match."
    end
    for t in 1:nr
        if 0 <= rates[t] >= 100
            errs["$(name)rates[$t]"] = "Rate should be between 0 and 100."
        end
    end
    for t in 1:nb-1
        if bands[t+1] <= bands[t]
            errs["$(name)bands[$t]"] = "Bands should be in ascending order."
        end

        function do_run( prs :: ParamsAndSettings; do_dumps = false, show_progress=true )::Integer
            settings = prs.settings
            @info "do_run entered"
            if show_progress
                update_progress( prs.hid, Progress( settings.uuid, "starting", 0, 0, 0, 0 ))
            end
            sys1 = deepcopy( DEFAULT_PARAMS )
            sys2 = deepcopy( DEFAULT_PARAMS)
            map_simple_to_full!( sys2, prs.params[2] )
            weeklyise!( sys1 )
            weeklyise!( sys2 )
            obs = Observable( Progress(settings.uuid, "",0,0,0,0))
            tot = 0
            of = on(obs) do p
                tot += p.step
                @info "monitor tot=$tot p = $(p)"
                if show_progress
                    update_progress( prs.hid, p )
                else
                    println( tot )
                end
            end
            results = do_one_run( settings, [sys1,sys2], obs )
            summaries = summarise_frames!( results, settings )
            # short_summary = make_short_summary( summaries )
            exres = calc_examples( DEFAULT_WEEKLY_PARAMS, sys2, settings )
            images = construct_images( settings, results, summaries, [sys1,sys2] )
            html = construct_html( settings, results, summaries )
            if do_dumps
                dump_summaries( settings, summaries )
            end
            endprog = Progress( settings.uuid, "completed", -99, -99, -99, -99 )
            aout = AllOutput( summaries, images, html, exres, endprog )
            cache_output( prs.hid, aout )
            return prs.hid
        end

    end
end



function validate( sp :: SimpleParams )::Dict
    errs = Dict()
    validate_ratebands!( errs, "tax", sp.taxrates, sp.taxbands )
    validate_ratebands!( errs, "ni", sp.nirates, sp.nibands )
    validate_value!(errs, "taxallowance", sp.taxallowance; max=100_000)
    validate_value!(errs, "child_benefit", sp.child_benefit)
    validate_value!(errs, "pension", sp.pension)
    validate_value!(errs, "scottish_child_payment", sp.scottish_child_payment)
    validate_value!(errs, "scp_age", sp.scp_age; min=0, max=21 )
    validate_value!(errs, "uc_single", sp.uc_single)
    validate_value!(errs, "uc_single", sp.uc_single)
    validate_value!(errs, "uc_taper", sp.uc_taper; min=0, max=100)
    return errs
end

