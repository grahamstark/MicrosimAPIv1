using ScottishTaxBenefitModel
using .STBParameters



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


function loaddefs() :: TaxBenefitSystem
    return get_default_system_for_fin_year(
        2026;
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

