
const BIG_A = 9999999999

@tags mutable struct SimpleParams{Float64} <: Subsys
    taxrates :: Vector{Float64} & (edit=(; label="Rates", min=0.0, max=100.0, agroup="Scottish Income Tax ", unit="%", prec=2))
    taxbands :: Vector{Float64} & (edit=(; label="Thresholds", min=0.0, agroup="Scottish Income Tax", unit="£s pa", prec=0 ))
    nirates :: Vector{Float64} & (edit=(; label="Rates", min=0.0, max=100.0, agroup="Employee National Insurance", unit="%", prec=2))
    nibands :: Vector{Float64} & (edit=(; label="Bands", min=0.0, agroup="Employee National Insurance", unit="£a pw", prec=2))
    taxallowance :: Float64  & (edit=(; label="Income Tax Allowance", min=0.0, unit="£s pa", prec=0))
    child_benefit :: Float64 & (edit=(; label="Child Benefit (1st Child)", min=0.0, unit="£s pw", prec=2))
    pension :: Float64 & (edit=(; label="New State Pension", min=0.0, unit="£s pw", prec=2))
    scottish_child_payment :: Float64 & (edit=(; label="Scottish Child Payment (Per Child))", min=0.0, unit="£s pw", prec=2))
    scp_age :: Int & (edit=(; label="Scottish Child Payment Maximum Age", min=0, max=18, unit="Years", prec=2))
    uc_single :: Float64 & (edit=(; label="Universal Credit: Allowance for Single Person", min=0.0, unit="£s pm", prec=2))
    uc_taper :: Float64 & (edit=(; label="Universal Credit: Withdrawal Rate", min=0.0, max=100.0, unit="%", prec=2))
end

@tags mutable struct UBIParams{Float64} <: Subsys
    abolished :: Bool & (edit=(; label="Don't Have A UBI (Please!)"))
    taxrates :: Vector{Float64} & (edit=(; label="Rates", min=0.0, max=100.0, group="Scottish Income Tax ", unit="%", prec=2))
    taxbands :: Vector{Float64} & (edit=(; label="Thresholds", min=0.0, agroup="Scottish Income Tax", unit="£s pa", prec=0 ))
    nirates :: Vector{Float64} & (edit=(; label="Rates", min=0.0, max=100.0, group="Employee National Insurance", unit="%", prec=2))
    nibands :: Vector{Float64} & (edit=(; label="Bands", min=0.0, agroup="Employee National Insurance", unit="£s pw", prec=2))
    taxallowance :: Float64  & (edit=(; label="Income Tax Allowance", min=0.0, unit="£s pa", prec=0))

    adult_amount :: Float64 & (edit=(; label="UBI: Amount Per Adult", min=0.0, unit="£s pw", prec=2))
    child_amount :: Float64 & (edit=(; label="UBI: Amount Per Child", min=0.0, unit="£s pw", prec=2))
    universal_pension :: Float64 & (edit=(; label="UBI: Amount Per Pension Age Person", min=0.0, unit="£s pw", prec=2))
    adult_age :: Int & (edit=(; label="UBI: Age of Adulthood", min=0, max=21, unit="Years"))
    retirement_age :: Int & (edit=(; label="UBI: Age of Retirement", min=50, unit="Years"))

    mt_bens_treatment :: UBIMTBenTreatment = ub_abolish & (edit=(; label="How to treat means-tested benefits" )

    # abolish_uc :: Bool & (edit=(; label="Abolish Universal Credit"))
    abolish_sickness_bens :: Bool & (edit=(; label="Abolish Sickness and Disablement Benefits?"))
    abolish_jsa_esa:: Bool & (edit=(; label="Abolish Contributory ESA/JSA?"))
    abolish_pensions :: Bool & (edit=(; label="Abolish The State Pension"))
    abolish_others :: Bool & (edit=(; label="Abolish All Other Benefits?"))

    ubi_as_mt_income :: Bool & (edit=(; label="Treat The UBI As Income for Means-Tested Benefits?"))
    ubi_taxable :: Bool & (edit=(; label="Make the UBI Taxable?"))

    # mt_bens_treatment :: UBEntitlement & (edit=(; label="UBI: How to treat Means-Tested Benefits", options=["1"])
end

StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{UBIParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{Progress}) = StructTypes.Struct()
StructTypes.StructType(::Type{Settings}) = StructTypes.Struct()

function loaddefs() :: TaxBenefitSystem
    return get_default_system_for_fin_year(
        2026;
        scotland = true,
        autoweekly = false )
end

mutable struct AllOutput
    summary  :: NamedTuple
    headlines :: NamedTuple
    images   :: NamedTuple
    html     :: NamedTuple
    typst    :: NamedTuple
    phunpack :: String
    examples :: Vector
    # progress :: Progress
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
        sys.scottish_child_payment.amounts[1],
        sys.scottish_child_payment.maximum_ages[1],
        sys.uc.age_25_and_over,
        sys.uc.taper )
end

function map_full_to_ubi( sys :: TaxBenefitSystem )::UBIParams
    itr, itb = copyArrays(
        sys.it.non_savings_rates,
        sys.it.non_savings_thresholds )
    nr, nb = copyArrays(
        sys.ni.primary_class_1_rates,
        sys.ni.primary_class_1_bands )


    return UBIParams(
        false, # don't abolish by default if we get here at all
        itr,
        itb,
        nr,
        nb,
        sys.it.personal_allowance,

        sys.ubi.adult_amount,
        sys.ubi.child_amount,
        sys.ubi.universal_pension,
        sys.ubi.adult_age,
        sys.ubi.retirement_age,
        sys.ubi.mt_bens_treatment,
        sys.ubi.abolish_sickness_bens,
        sys.ubi.abolish_jsa_esa,
        sys.ubi.abolish_pensions,
        sys.ubi.abolish_others,
        sys.ubi.ub_as_mt_income,
        sys.ubi.ub_taxable )
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

    sys.scottish_child_payment.amounts[1] = sm.scottish_child_payment
    sys.scottish_child_payment.maximum_ages[1] = sm.scp_age

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

function map_simple_to_full!( sys ::  TaxBenefitSystem, ubi :: UBIParams )
    sys.ubi.abolished = ubi.abolished
    sys.it.non_savings_rates = copy(ubi.taxrates)
    br = sys.it.non_savings_basic_rate
    orig = DEFAULT_PARAMS.it.non_savings_rates[br]
    sys.it.non_savings_basic_rate = nearest( sys.it.non_savings_rates, orig )
    @info " setting sys.it.non_savings_basic_rate to " sys.it.non_savings_basic_rate " orig = " orig
    sys.it.non_savings_thresholds = copy(ubi.taxbands)
    sys.ni.primary_class_1_rates = copy(ubi.nirates)
    sys.ni.primary_class_1_bands = copy(ubi.nibands)
    sys.it.personal_allowance = ubi.taxallowance
    sys.ubi.mt_bens_treatment = if(ubi.abolish_housing && ubi.abolish_uc)
        ub_abolish
    elseif ubi.abolish_uc
        ub_keep_housing
    else
        ub_as_is
    end
    sys.ubi.abolish_sickness_bens = ubi.abolish_sickness_bens
    sys.ubi.abolish_jsa_esa = ubi.abolish_jsa_esa
    sys.ubi.abolish_pensions = ubi.abolish_pensions
    sys.ubi.abolish_others = ubi.abolish_others
    sys.ubi.ub_as_mt_income = ubi.ubi_as_mt_income
    sys.ubi.ub_taxable = ubi.ubi_taxable
    sys.ubi.adult_amount = ubi.adult_amount
    sys.ubi.child_amount = ubi.child_amount
    sys.ubi.universal_pension = ubi.universal_pension
    sys.ubi.adult_age = ubi.adult_age
    sys.ubi.retirement_age = ubi.retirement_age
end

const DEFAULT_MINI_PARAMS = Dict{Symbol,Subsys}([
    :SimpleParams => map_full_to_simple( DEFAULT_PARAMS ),
    :UBIParams    => map_full_to_ubi( DEFAULT_PARAMS )])

#
# Foolish decision to index runs by UUIDs...
#
const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")
const DEF_PROGRESS = Progress( BASE_UUID, "na", 0, 0, 0, 0 )

SCOTBEN_BASE_RESULTS = (;) # declared this way for convoluted reasons & initialised in lazy below
function get_scotben_base_results()::NamedTuple
     global SCOTBEN_BASE_RESULTS
     if length( SCOTBEN_BASE_RESULTS ) == 0
        SCOTBEN_BASE_RESULTS = do_default_run()
     end
     return SCOTBEN_BASE_RESULTS
end

function do_default_run()::NamedTuple
    settings = Settings()
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    tot = 0
    of = on(obs) do p
        tot += p.step
        println( tot )
    end
    return do_one_run( settings, [DEFAULT_WEEKLY_PARAMS], obs )
end

graphlock = ReentrantLock()

function do_run(
    user_id :: Integer,
    model_name :: String,
    edition :: String,
    run_id :: Integer,
    sys :: TaxBenefitSystem;
    update_progress::Function,
    do_dumps :: Bool )::AllOutput
    @info "do_run entered"
    settings = Settings()
    # jam on a writable output dir since the network version may have /tmp/ blocked.
    settings.output_dir = joinpath( homedir(), "model-runs", model_name, edition )
    update_progress( user_id, model_name, edition, run_id, Progress( settings.uuid, "starting", 0, 0, 0, 0 ))
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    tot = 0
    of = on(obs) do p
        tot += p.step
        # @info "monitor tot=$tot p = $(p)"
        update_progress( user_id, model_name, edition, run_id,  p )
    end
    results = do_one_run( settings, [sys], obs )
    # merge with defaults
    base_results = get_scotben_base_results()
    insert!( results.hh, 1, base_results.hh[1] )
    insert!( results.bu, 1, base_results.bu[1] )
    insert!( results.indiv, 1, base_results.indiv[1] )
    insert!( results.income, 1, base_results.income[1] )
    bh = SFCBehavioural.calc_behavioural_response(
        results.income[1],
        results.income[2],
        DEFAULT_WEEKLY_PARAMS,
        sys )
    #insert!( results.behavioural_results, 1, base_results.behavioural_results[1] )
    push!( results.behavioural_results, bh )
    @info results.behavioural_results

    summaries = summarise_frames!( results, settings )
    headlines = mv.format_headline_numbers( summaries.headline_figures[2] )
    exres = calc_examples( DEFAULT_WEEKLY_PARAMS, sys, settings )
    html_tabs = mv.construct_tables( settings, results, summaries, mv.MV_HTML())
    typst_tabs = mv.construct_tables( settings, results, summaries, mv.MV_TYPST())
    @info  "tabs OK"
    # makie not threadsafe, so ...
    @time graphs = lock(graphlock) do
        @info "generating graphs"
        mv.construct_images( settings, results, summaries, [DEFAULT_WEEKLY_PARAMS, sys] )
    end
    @info "graphs OK"
    path, zippath = mv.phunpackify( settings, graphs, typst_tabs, html_tabs, summaries )
    @info "dumping to" path
    if do_dumps
        dump_frames( path, results )
    end
    update_progress( user_id, model_name, edition, run_id,
        Progress( settings.uuid, "completed", -99, -99, -99, -99 ))
    return AllOutput( summaries, headlines, graphs, html_tabs, typst_tabs, zippath, exres )
end

"""
Overloaded by miniparam
"""
function do_run(
    user_id :: Integer,
    model_name :: String,
    model_edition :: String,
    run_id :: Integer,
    simple :: SimpleParams;
    update_progress::Function,
    do_dumps :: Bool )::AllOutput
    sys = deepcopy( DEFAULT_PARAMS)
    map_simple_to_full!( sys, simple )
    weeklyise!( sys )
    return do_run(
        user_id,
        model_name,
        model_edition,
        run_id,
        sys,
        update_progress=update_progress,
        do_dumps=do_dumps )
end

function do_run(
    user_id :: Integer,
    model_name :: String,
    model_edition :: String,
    run_id :: Integer,
    ubi :: UBIParams;
    update_progress::Function,
    do_dumps :: Bool )::AllOutput
    sys = deepcopy( DEFAULT_PARAMS)
    map_simple_to_full!( sys, ubi )
    weeklyise!( sys )
    return do_run(
        user_id,
        model_name,
        model_edition,
        run_id,
        sys,
        update_progress=update_progress,
        do_dumps=do_dumps )
end
