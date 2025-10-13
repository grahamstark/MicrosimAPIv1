const TEXT_DESC = md"""

    taxrates :: Vector{T} :: min 0 max 100 pct
    taxbands :: Vector{T} :: min 0 max unlimited
    nirates :: Vector{T} :: min 0 max 100 pct
    nibands :: Vector{T} :: min 0 max 100 annual
    taxallowance :: T min 0 max 100_000 annual
    child_benefit :: T min 0 max 1000 weekly
    pension :: T  min 0 max 1000 weekly
    scottish_child_payment :: T  min 0 max 1000 weekly
    scp_age :: Int min 0 max 21 
    uc_single :: T  min 0 max 1000 weekly
    uc_taper :: T  min 0 max 100 pct
"""

const OUTPUT_ITEMS = OrderedDict([
    "headline_figures"=>"Headline Summary (json)",
    "quantiles"=>"Quantiles (50 rows, 4 cols) (csv)", 
    "deciles" => "Quantiles (10 rows, 4 cols) (csv)",
    "income_summary" => "Income Summary (csv)", 
    "poverty" => "Poverty Measures (json)", 
    "inequality" => "Inequality Measures (json)", 
    "metrs" => "Marginal Effective Tax Rates histogram (csv)", 
    "child_poverty" => "Child Poverty Count (json)",
    "gain_lose/ten_gl" => "Gain Lose by Tenure (csv)",
    "gain_lose/dec_gl" => "Gain Lose by Decile (csv)",
    "gain_lose/children_gl" => "Gain Lose by Number of Children (csv)",
    "gain_lose/hhtype_gl" => "Gain Lose by Household Size (csv)",
    "poverty_lines" => "Computed Poverty Lines (json)",
    "short_income_summary"=>"Short Income Summary (csv)",
    "income_hists"=>"Histogram of Incomes (csv)",
    "povtrans_matrix"=>"Poverty Transitions Matrix (csv)",
    "examples"=>"Simple Examples (json)"
])

const CSV_ITEMS = [
    "quantiles",
    "deciles",
    "income_summary", 
    "metrs", 
    "gain_lose",
    "short_income_summary",
    "income_hists",
    "povtrans_matrix"]


const LABELS = OrderedDict([
    "taxrates" => "Tax Rates (%)",
    "taxbands" => "Tax Bands (£pa)",
    "nirates" => "NI Rates (%)",
    "nibands" => "NI Bands (£pa)",
    "taxallowance" => "Tax Allowance (£pa)",
    "child_benefit" => "Child Benefit (£pw)",
    "pension" => "Pension  (£pa)",
    "scottish_child_payment" => "Scottish Child Payment (£pa)",
    "scp_age" => "Scottish Child Payment Maximum Age (years)",
    "uc_single" => "Universal Credit Single Person (£pm)",
    "uc_taper" => "Universal Credit Taper (pct)"])

const RUN_STATUSES = OrderedDict([
    "submitted" => "Job Submitted",
    "do-one-run-start" => "Run Started",
    "weights" => "Weights Calculation",
    "disability_eligibility" => "Calibrating Disability Eligibility",
    "starting" => "Main Calculations Starting",
    "run" => "Running Through Households",
    "dumping_frames" => "Dumping Data to Files",
    "do-one-run-end" => "Run Ended",
    "completed" => "Task Completed - Output is Ready"])

function list_default_systems()
    choices=OrderedDict()
    for financial_year in 2025:-1:2019
        for scottish in [true,false]
            sn = scottish ? "Scotland" : "rUK"
            default = financial_year == 2025 && scottish ? true : false
            name = "System FY $(financial_year)-$(financial_year+1); $sn"
            choices[name] = (;name,financial_year,scottish,default)
        end
    end
    return choices 
end

const DEFAULT_SYSTEMS = list_default_systems()