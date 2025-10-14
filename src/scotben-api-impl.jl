const BIG_A = 9999999999

struct SimpleParams{T}
    taxrates :: Vector{T}
    taxbands :: Vector{T}
    nirates :: Vector{T}
    nibands :: Vector{T}
    taxallowance :: T
    child_benefit :: T
    pension :: T
    scottish_child_payment :: T
    scp_age :: Int
    uc_single :: T
    uc_taper :: T
end

StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{Progress})  = StructTypes.Struct()

function paramsfrompayload( payload )
    @show payload
    pars = JSON3.read(payload, SimpleParams{Float64})
    return pars
end

function validate_value!( d::Dict, name::String, v :: Real ; min=0, max=1000 )
    if (v < min) || (v > max)
        d[name] = "$(name) is outside the range $(min) - $(max)"
    end
    d
end

function validate_ratebands!( d::Dict, name::String, rates::Vector, bands::Vector)
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
    end
end

function validate( sp :: SimpleParams )::Dict
    errs = Dict()
    validate_ratebands!( errs, "tax", sp.taxrates, sb.taxbands )
    validate_ratebands!( errs, "ni", sp.nirates, sb.nibands )
    validate_value!(errs, "taxallowance", sp.taxallowance; max=100_000)
    validate_value!(errs, "child_benefit", sp.child_benefit)
    validate_value!(errs, "pension", sp.pension)
    validate_value!(errs, "scottish_child_payment", sp.scottish_child_payment)
    validate_value!(errs, "scp_age", sp.scp_age; min=0, max=21 )
    validate_value!(errs, "uc_single", sp.uc_single)
    validate_value!(errs, "uc_single", sp.uc_single)
    validate_value!(errs, "uc_taper", sp.uc_taper; min=0, max=100)
    errs
end

function loaddefs() :: TaxBenefitSystem 
    return get_default_system_for_fin_year( 
        2025; 
        scotland = true,
        autoweekly = false )    
end

function weeklyparams() :: TaxBenefitSystem
   pars = deepcopy( DEFAULT_PARAMS )
   weeklyise!( pars )
   pars
end

const DEFAULT_PARAMS ::  TaxBenefitSystem = loaddefs()

const DEFAULT_WEEKLY_PARAMS :: TaxBenefitSystem = weeklyparams()

"""
Chop off top band if needed 
"""
function copyArrays( r :: Vector, b :: Vector ) :: Tuple
    ar = copy(r)
    ab = copy(b)
    start = firstindex(ar)
    tstop = lastindex(ab)
    rstop = lastindex(ar)
    @assert (rstop - tstop) <= 1
    if rstop == tstop
        tstop -= 1
    end    
    (ar,ab[start:tstop])
end

function map_full_to_simple( sys :: TaxBenefitSystem )::SimpleParams
    itr, itb = copyArrays( 
        sys.it.non_savings_rates, 
        sys.it.non_savings_thresholds )
    nr, nb = copyArrays(
        sys.ni.primary_class_1_rates,
        sys.ni.primary_class_1_bands )
    return SimpleParams(
        itr,
        itb,
        nr,
        nb,
        sys.it.personal_allowance,
    	sys.nmt_bens.child_benefit.first_child,
		sys.nmt_bens.pensions.new_state_pension,
		sys.scottish_child_payment.amount,
		sys.scottish_child_payment.maximum_age,
	    sys.uc.age_25_and_over,
		sys.uc.taper )
end

function roundm( v::T, m::T, digits=2)::T where T<:Number
    v *= m
    round(v,digits=digits)
end

function nearest( a :: AbstractArray, v :: Number)
    m = 999999999999999 
    p = 0
    n = length(a)
    for i in 1:n
        d = abs( a[i]-v )      
        if d <= m # <= is a bit of a hack - suppose you have 2 20s...
            m = d
            p = i
        end
    end
    return p
end

function map_simple_to_full!( sys ::  TaxBenefitSystem, sm :: SimpleParams )
    sys.it.non_savings_rates = copy(sm.taxrates)
    br = sys.it.non_savings_basic_rate
    orig = DEFAULT_PARAMS.it.non_savings_rates[br]
    sys.it.non_savings_basic_rate = nearest( sys.it.non_savings_rates, orig )
    @info " setting sys.it.non_savings_basic_rate to " sys.it.non_savings_basic_rate " orig = " orig
    sys.it.non_savings_thresholds = copy(sm.taxbands)
    sys.ni.primary_class_1_rates = copy(sm.nirates)
    sys.ni.primary_class_1_bands = copy(sm.nibands)
    sys.it.personal_allowance = sm.taxallowance

    p = sm.child_benefit/sys.nmt_bens.child_benefit.first_child
    sys.nmt_bens.child_benefit.first_child = sm.child_benefit
    sys.nmt_bens.child_benefit.other_children = roundm( sys.nmt_bens.child_benefit.other_children, p)

    p = sm.pension / sys.nmt_bens.pensions.new_state_pension
    sys.nmt_bens.pensions.new_state_pension = sm.pension
    sys.nmt_bens.pensions.cat_a  = roundm( sys.nmt_bens.pensions.cat_a, p )
    sys.nmt_bens.pensions.cat_b  = roundm( sys.nmt_bens.pensions.cat_b, p )
    sys.nmt_bens.pensions.cat_d  = roundm( sys.nmt_bens.pensions.cat_d, p )
    sys.nmt_bens.pensions.cat_b_survivor  = roundm( sys.nmt_bens.pensions.cat_b_survivor, p )

    sys.scottish_child_payment.amount = sm.scottish_child_payment
    sys.scottish_child_payment.maximum_age = sm.scp_age

    sys.uc.taper = sm.uc_taper
    p = sm.uc_single/sys.uc.age_25_and_over
    sys.uc.age_25_and_over = sm.uc_single
    sys.uc.threshold = roundm( sys.uc.threshold, p )
    sys.uc.age_18_24  = roundm( sys.uc.age_18_24 , p )
    sys.uc.age_25_and_over  = roundm( sys.uc.age_25_and_over , p )
    sys.uc.couple_both_under_25  = roundm( sys.uc.couple_both_under_25 , p )
    sys.uc.couple_oldest_25_plus  = roundm( sys.uc.couple_oldest_25_plus , p )
    sys.uc.minimum_income_floor_hours = roundm( sys.uc.minimum_income_floor_hours, p )
    sys.uc.first_child   = roundm( sys.uc.first_child  , p )
    sys.uc.subsequent_child  = roundm( sys.uc.subsequent_child , p )
    sys.uc.disabled_child_lower  = roundm( sys.uc.disabled_child_lower , p )
    sys.uc.disabled_child_higher  = roundm( sys.uc.disabled_child_higher , p )
    sys.uc.limited_capcacity_for_work_activity = roundm( sys.uc.limited_capcacity_for_work_activity, p )
    sys.uc.carer  = roundm( sys.uc.carer , p )
    sys.uc.ndd = roundm( sys.uc.ndd, p )
    sys.uc.childcare_max_2_plus_children  = roundm( sys.uc.childcare_max_2_plus_children , p )
    sys.uc.childcare_max_1_child  = roundm( sys.uc.childcare_max_1_child , p )
    sys.uc.work_allowance_w_housing = roundm( sys.uc.work_allowance_w_housing, p )
    sys.uc.work_allowance_no_housing = roundm( sys.uc.work_allowance_no_housing, p )
end

const DEFAULT_SIMPLE_PARAMS :: SimpleParams = map_full_to_simple( DEFAULT_PARAMS )

#
# Foolish decision to index runs by UUIDs...
#
const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")
const DEF_PROGRESS = Progress( BASE_UUID, "na", 0, 0, 0, 0 )

#
# This goes in the sessions and job queues
#
@with_kw mutable struct ParamsAndSettings
	settings = RunSettings.DEFAULT_SETTINGS # use thing declared in Scottis..RunSettings to avoid weird precompilation error
	params = [DEFAULT_SIMPLE_PARAMS, DEFAULT_SIMPLE_PARAMS]
    hid = riskyhash( [RunSettings.DEFAULT_SETTINGS, DEFAULT_SIMPLE_PARAMS])
end

function hid( prs :: ParamsAndSettings )::UInt
    return riskyhash( [prs.settings, prs.params[2]])
end

#
# This holds the data in the cacbe
#
struct AllOutput
	summary  :: NamedTuple
    # short_summary :: NamedTuple
	examples :: Vector
    progress :: Progress
end

const NULL_ALL_OUTPUT = AllOutput( (;), [], DEF_PROGRESS )

#
# User data in a session
#
#=
@with_kw mutable struct SessionEntry
    session_id = ""
    last_accessed = now()
    created_at = now()
    params_and_settings = ParamsAndSettings()   
    h = UInt(0)
end
=#

#
# 3 data structures
# - SESSION - Dict of user data, keyed by session_id
# - CACHED_RESULTS - Dict, keyed by hash of parameters
# - JOB_QUEUE - Channel of
#
const QSIZE = 32
const SESSIONS = Dict{String, ParamsAndSettings}()
const CACHED_RESULTS = Dict{UInt, AllOutput}()
JOB_QUEUE = Channel{ParamsAndSettings}(QSIZE)

#
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 4
# configure logger; see: https://docs.julialang.org/en/v1/stdlib/Logging/index.html
# and: https://github.com/oxinabox/LoggingExtras.jl
logger = FileLogger(joinpath("log", "microsim-api-log.txt"))
global_logger(logger)
LogLevel( Logging.Debug )

#
# needs to be here 
#
function cache_output( h:: UInt, allo::AllOutput)
	CACHED_RESULTS[h] = allo
end

function update_progress( h :: UInt, p :: Progress )
    CACHED_RESULTS[h].progress = p
end

function do_run( prs :: ParamsAndSettings; do_dumps = false )
    settings = prs.settings
    @info "do_run entered"
    update_progress( prs.hid, Progress( settings.uuid, "starting", 0, 0, 0, 0 ))
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
        update_progress( prs.hid, p )
    end
    results = do_one_run( settings, [sys1,sys2], obs )
    summaries = summarise_frames!( results, settings )
    # short_summary = make_short_summary( summaries )
    exres = calc_examples( DEFAULT_WEEKLY_PARAMS, sys, settings )
    endprog = Progress( settings.uuid, "completed", -99, -99, -99, -99 )
    aout = AllOutput( summaries, exres, endprog )
    cache_output( prs.hid, aout )
    if do_dumps
        dump_summaries( settings, summaries )
    end
end

function submit_job( prs :: ParamsAndSettings )
    @info "submit_job entered"
    @assert (! haskey( CACHED_RESULTS, prs.hid )) # if so, why are we here?
    CACHED_RESULTS[h] = NULL_ALL_OUTPUT # initialise blank entry
    put!( JOB_QUEUE, prs )
	@info "submit exiting queue is now $JOB_QUEUE"
end

function calc_one()
	while true
		@info "calc_one entered"
		prs = take!( JOB_QUEUE )
        @info "params taken from JOB_QUEUE; got params"
		do_run( prs )
		@info "model run OK; putting results into CACHED_RESULTS"		
	end
end

function allfromsession(id::String)
    if( ! haskey( SESSIONS, id ))
        SESSIONS[id] = ParamsAndSettings()
    end
    return SESSIONS[id]
end

function paramsfromsession(id::String)::SimpleParams
    prs = allfromsession(id)
    return prs.params[2]
end

function settingsfromsession(id::String)::Settings
    prs = allfromsession(id)
    return prs.settings
end

function hidfromsession(id::String)::UInt
    prs = allfromsession(id)
    return prs.hid
end

function getparams()
    pars = paramsfromsession()
    (:pars=>pars,:def=>DEFAULT_SIMPLE_PARAMS) |> json
end

"""

"""
function scotben_params_list_available()
    session = GenieSession.session() #  :: GenieSession.Session 
    @show session
    id = session.id
    @show id
    return json(DEFAULT_SYSTEMS)
end

"""

"""
function scotben_params_initialise() # req::HTTP.Request, resp :: HTTP.Response)
    session = GenieSession.session() #  :: GenieSession.Session 
    @show session
    id = session.id
    @show id
    prs = allfromsession(id)
    prs.params[2]=deepcopy(DEFAULT_SIMPLE_PARAMS)
    prs.hid = hid( prs )
    @show SESSIONS
    return json( prs.params[2] )
end

"""

"""
function scotben_params_set()
    session = GenieSession.session() #  :: GenieSession.Session 
    id = session.id
    pars = paramsfrompayload( rawpayload() )
    errs = validate( pars )
    if length( errs ) == 0
        SESSIONS[id].params_and_settings.params[2] = pars
        SESSIONS[id].hid = hid( SESSIONS[id].params_and_settings )
        return json(pars)
    else
        return json( errs )
    end
end

"""

"""
function scotben_params_validate()
    session = GenieSession.session() #  :: GenieSession.Session 
    id = session.id
    pars = paramsfrompayload( rawpayload() )
    errs = validate( pars )
    return json( errs )
end


"""

"""
function scotben_params_describe()
    return TEXT_DESC # server objects to md"...  
end

"""

"""
function scotben_params_subsys()
    @show "/scotben/params/subsys"
    return "Subsys Not Implemented."
end

"""

"""
function scotben_params_helppage()
    return string(TEXT_DESC)
end

"""

"""
function scotben_params_labels()
    return json( LABELS )
end

"""

"""
function scotben_settings_set()
    return "Set Settings"
end

"""

"""
function scotben_settings_initialise()
    return "Initialise"
end

"""

"""
function scotben_settings_validate()
    return "Validate"
end

"""

"""
function scotben_settings_describe()
    return "Describe"
end
"""

"""
function scotben_settings_helppage(  )
    return "HelpPage"
end

"""

"""
function scotben_settings_labels()
    return "Labels"
end

"""

"""
function scotben_run_submit()
    session = GenieSession.session() #  :: GenieSession.Session 
    id = session.id    
    prs = allfromession(id)
    res = get(CACHED_RESULTS, prs.hid, nothing )
    if isnothing( res )
        try
            submit_job( prs )
            return json((; error="ok", info=Progress( BASE_UUID, "submitted", 0, 0, 0, 0 ) ))
        catch e
            return json((; error="error", info=""))
        end
    else
        return json((; error="ok", info=res.progress ))
    end
end

"""

"""
function scotben_run_status()
    session = GenieSession.session() #  :: GenieSession.Session 
    id = session.id
    @show CACHED_RESULTS
    @show JOB_QUEUE
    id = GenieSession.id(req, resp )
    prs = allfromsession(id)
    res = Base.get(CACHED_RESULTS, prs.hid, nothing )
    if isnothing( res )
        return json((; error="no_run", info="" ))
    else
        return json((; error="ok", info=res.progress ))
    end
    return "Status"
end

"""

"""
function scotben_run_abort()
    return "We Can't Abort.."
end


"""

"""
function scotben_run_statuses()
    return json( RUN_STATUSES )
end


"""

"""
function scotben_output_items()
    return json(OUTPUT_ITEMS)
end

"""

"""
function scotben_output_phunpak()
    output_zipfile="" # TODO
    return HTTP.Response(
        200,
        ["Content-Type" => "application/zip"],
        body=output_zipfile )
end

"""

"""
function scotben_output_labels( )
    return "Labels, possibly."
end

"""

"""
function scotben_output_fetch_item( item, subitem )
    session = GenieSession.session() #  :: GenieSession.Session 
    id = session.id
    prs = allfromsession( id )
    res = Base.get(CACHED_RESULTS, prs.hid, nothing )
    if ! isnothing( res )
        ns = Symbol( item )
        ctype = if item in CSV_ITEMS
            "text/csv"
        else
            "application/json"
        end
        if item == "gain_lose"
            sns = Symbol( subitem )            
        end
    end
end