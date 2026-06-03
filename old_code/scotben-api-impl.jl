"""

"""
function params_list_available()
    id = get_session_id()
    #=
    session = GenieSession.session(params()) #  :: GenieSession.Session
    @info session
    id = session.id
    =#
    @info id
    return json( (;session_id=id, systems=DEFAULT_SYSTEMS))
end

"""

"""
function params_initialise()
    id = get_session_id()
    @info id
    prs = allfromsession(id)
    prs.params[2]=deepcopy(DEFAULT_SIMPLE_PARAMS)
    prs.hid = hid( prs )
    # @info SESSIONS
    return json((;session_id=id, params=prs.params[2], default=DEFAULT_SIMPLE_PARAMS ))
end

"""

"""
function params_get()
    id = get_session_id()
    @info "scotben_params_get entered"
    @info id
    prs = allfromsession(id)
    # @info SESSIONS
    return json((;session_id=id, params=prs.params[2], default=DEFAULT_SIMPLE_PARAMS))
end


"""

"""
function params_set()
    id = get_session_id()
    @info  "scotben_params_set"
    @info id
    pars_and_id = paramsfrompayload()
    @assert id == pars_and_id.session_id
    @info params
    errs = validate( pars_and_id.params )
    if length( errs ) == 0
        SESSIONS[id].params[2] = pars_and_id.params
        SESSIONS[id].hid = hid( SESSIONS[id] )
        return json((; session_id=id, params=pars_and_id.params, default=DEFAULT_SIMPLE_PARAMS))
    else
        return json((;session_id=id, errs=errs ))
    end
end

"""

"""
function params_validate()
    id = get_session_id()
    @info payload()
    pars_and_id = paramsfrompayload()
    @info pars_and_id
    errs = validate( pars_and_id.params )
    @info errs
    return json((;session_id=id, errs=errs ))
end


"""

"""
function params_describe()
    return TEXT_DESC
end

"""

"""
function params_subsys()
    @info "/scotben/params/subsys"
    return "Subsys Not Implemented."
end

"""

"""
function params_helppage()
    return string(TEXT_DESC)
end

"""

"""
function params_labels()
    return json( LABELS )
end

"""

"""
function settings_set()
    return "Set Settings"
end

"""

"""
function settings_initialise()
    return "Settings Initialise"
end

"""

"""
function settings_validate()
    return "Settings Validate"
end

"""

"""
function settings_describe()
    return "Settings Describe"
end
"""

"""
function settings_helppage(  )
    return "Settings HelpPage"
end

"""

"""
function settings_labels()
    return "Settings Labels"
end

"""

"""
function run_submit()
    id = get_session_id()
    prs = allfromsession(id)
    res = get(CACHED_RESULTS, prs.hid, nothing )
    @info CACHED_RESULTS
    @info JOB_QUEUE
    @info prs
    @info res
    if isnothing( res )
        try
            @info  "submitting job"
            submit_job( prs )
            return json((; session_id=id, error="ok", info=Progress( BASE_UUID, "submitted", 0, 0, 0, 0 )))
        catch e
            @info  "exception $e"
            return json((;session_id=id, error="error", info=e))
        end
    else # already submitted
        return json((;session_id=id, error="ok", info=res.progress ))
    end
end

"""

"""
function run_status()
    id = get_session_id()
    for t in 1:5
        @info "scotben_run_status got id = " id
        prs = allfromsession(id)
        @info "getting hid try # $tries" prs.hid
        res = Base.get(CACHED_RESULTS, prs.hid, nothing )
        if ! isnothing( res )
            @info "got progress as " res.progress
            return json((;session_id=id, error="ok", info=res.progress ))
        end
        sleep(1)
    end
    return json((;session_id=id, error="no_run", info="retried 5 times." ))
    return "Status"
end

"""

"""
function run_abort()
    return "We Can't Abort.."
end


"""

"""
function run_statuses()
    return json( RUN_STATUSES )
end


"""

"""
function output_items()
    return json(OUTPUT_ITEMS)
end

"""

"""
function output_phunpak()
    output_zipfile="" # TODO
    return HTTP.Response(
        200,
        ["Content-Type" => "application/zip"],
        body=output_zipfile )
end

function middleware()
    user = payload(:user,nothing)
    model = payload(:model)
    edition = payload(:edition)
    return handle_middle( user, nothing, model, edition)
end


"""

"""
function output_labels()
    return "Labels, possibly."
end

function get_cached_results( prs :: ParamsAndSettings )
    res = Base.get( CACHED_RESULTS, prs.hid, nothing )
    # deferred initialisation of default run. This gets round some bollocks
    # about taking ParamsAndSettings before RunSettings.Settings is fully loaded
    # .. don't really understand.
    if isnothing( res ) && (prs.hid === ParamsAndSettings().hid)
        do_default_run()
        res = Base.get( CACHED_RESULTS, prs.hid, nothing )
    end
    return res
end

"""

"""
function output_fetch_item()
    id = get_session_id()
    prs = allfromsession( id )
    @info "scotben_output_fetch_item getting results for id/hid" id prs.hid
    @info "available cached results are " Base.keys( CACHED_RESULTS )
    res = get_cached_results( prs )
    if ! isnothing( res )
        format = payload(:format)
        item = payload(:item)
        subitem = payload(:subitem,nothing)
        sub2 = payload(:sub2,nothing)
        ns = Symbol( item )
        if format == "json"
            if item == "examples"
                s = JSON3.write((;session_id=id, item=res.examples); allow_inf=true)
                s = replace(s,"Infinity"=>"99999999")
                return HTTP.Response(
                    200,
                    ["Content-Type" => "application/json"], s )
            elseif item == "gain_lose"
                sns = Symbol( subitem )
                return json((; session_id=id, item=res.summary.gain_lose[2][sns]))
            elseif item == "headlines"
                headlines = format_headline_numbers(res.summary.headline_figures[2])
                return json((;
                    session_id=id,
                    item=headlines ))
            else
                # this just deals with INFs in the output, which json objects to:
                s = JSON3.write((;session_id=id, item=res.summary[ns]); allow_inf=true)
                s = replace(s,"Infinity"=>"99999999")
                return HTTP.Response(
                    200,
                    ["Content-Type" => "application/json"], s )
            end
        elseif format == "images"
            keys = item
            if subitem == "thumb"
                keys *= "_thumb"
            end
            key = Symbol( keys )
            s = fig_to_svg_string(res.images[key])
            return HTTP.Response(
                200,
                ["Content-Type" => "image/svg+xml"], s )
            # ..
        elseif format == "html"
            s = res.html[ns]
            return HTTP.Response(
                200,
                ["Content-Type" => "text/html"], s )
            # ...
        end
    else
        return HTTP.Response(
                404, body="No such output yet for hid $(prs.hid)" )
    end
end
