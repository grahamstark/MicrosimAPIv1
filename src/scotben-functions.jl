using ScottishTaxBenefitModel
using .BCCalcs
using .Definitions
using .ExampleHelpers
using .FRSHouseholdGetter
using .GeneralTaxComponents
using .LocalLevelCalculations
using .ModelHousehold
using .Monitor
using .Runner
using .RunSettings
using .SimplePovertyCounts: GroupPoverty
using .SingleHouseholdCalculations
using .STBIncomes
using .STBOutput
using .STBParameters
using .Utils

import MicroVisualisations as mv
using UUIDs

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

struct BIParams{T}
    taxrates :: Vector{T}
    taxbands :: Vector{T}
    nirates :: Vector{T}
    nibands :: Vector{T}
    taxallowance :: T

    abolish_uc :: Bool
    abolish_sick :: Bool
    abolish_pensions :: Bool
    abolish_pencred :: Bool
    abolish_hb :: Bool
    abolish_ctb :: Bool
    ubi_as_mt_income :: Bool
    ubi_taxable :: Bool

    bi_adult :: T
    bi_child :: T
    bi_pensioner :: T
    bi_adult_age :: T
    bi_pens_age :: Int
    mt_bens_treatment :: String
end

StructTypes.StructType(::Type{SimpleParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{BIParams}) = StructTypes.Struct()
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

const DEFAULT_SIMPLE_PARAMS :: SimpleParams = map_full_to_simple( DEFAULT_PARAMS )

#
# Foolish decision to index runs by UUIDs...
#
const BASE_UUID = UUID("985c312f-129b-4acd-9e40-cb629d184183")
const DEF_PROGRESS = Progress( BASE_UUID, "na", 0, 0, 0, 0 )

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

const BASE_RESULTS = do_default_run()

function do_run(
    user_id :: Integer,
    model_name :: String,
    edition :: String,
    run_id :: Integer,
    simple :: SimpleParams;
    update_progress::Function,
    do_dumps :: Bool )::AllOutput
    @info "do_run entered"
    settings = Settings()
    update_progress( user_id, model_name, edition, run_id, Progress( settings.uuid, "starting", 0, 0, 0, 0 ))
    sys = deepcopy( DEFAULT_PARAMS)
    map_simple_to_full!( sys, simple )
    weeklyise!( sys )
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    tot = 0
    of = on(obs) do p
        tot += p.step
        # @info "monitor tot=$tot p = $(p)"
        update_progress( user_id, model_name, edition, run_id,  p )
    end
    results = do_one_run( settings, [sys], obs )
    # merge with defaults
    insert!( results.hh, 1, BASE_RESULTS.hh[1] )
    insert!( results.bu, 1, BASE_RESULTS.bu[1] )
    insert!( results.indiv, 1, BASE_RESULTS.indiv[1] )
    insert!( results.income, 1, BASE_RESULTS.income[1] )
    insert!( results.behavioural_results, 1, BASE_RESULTS.behavioural_results[1] )
    summaries = summarise_frames!( results, settings )
    # short_summary = make_short_summary( summaries )
    exres = calc_examples( DEFAULT_WEEKLY_PARAMS, sys, settings )
    # images = construct_images( settings, results, summaries, [DEFAULT_WEEKLY_PARAMS,sys] )
    # html = construct_html( settings, results, summaries )
    html_tabs = construct_tables( settings, results, summary, mv.MV_HTML())
    typst_tabs = construct_tables( settings, results, summary, mv.MV_TYPST())
    println( "tabs OK")
    graphs = construct_images( settings, results, summary, sys )
    println( "graphs OK")
    path, zippath = mv.phunpackify( settings, graphs, typst_tabs, html_tabs, zippath, summary )
    #=
    if do_dumps
        dump_summaries( settings, summaries )
    end
    =#
    update_progress( user_id, model_name, edition, run_id,
        Progress( settings.uuid, "completed", -99, -99, -99, -99 ) )
    return AllOutput( summaries, graphs, html_tabs, exres )
end

