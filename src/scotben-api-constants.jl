const TEXT_DESC = OrderedDict([
    "taxrates" =>  " Vector :: min 0 max 100 pct",
    "taxbands" =>  " Vector :: min 0 max unlimited",
    "nirates" =>  " Vector :: min 0 max 100 pct",
    "nibands" =>  " Vector :: min 0 max 100 annual",
    "taxallowance" =>  "min 0 max 100_000 annual",
    "child_benefit" =>  "min 0 max 1000 weekly",
    "pension" =>  "min 0 max 1000 weekly",
    "scottish_child_payment" =>  "Int min 0 max 1000 weekly",
    "scp_age" =>  " Int min 0 max 21 ",
    "uc_single" =>  "min 0 max 1000 weekly",
    "uc_taper" =>  " min 0 max 100 pct"])

const OUTPUT_ITEMS = OrderedDict([
    "headline_figures"=>"Headline Summary ",
    "quantiles_df"=>"Quantiles (50 rows serialsed DF) ", 
    "deciles_df" => "Quantiles (10 rows serialsed DF) ",
    "income_summary" => "Income Summary ", 
    "poverty" => "Poverty Measures ", 
    "inequality" => "Inequality Measures ", 
    "metrs" => "Marginal Effective Tax Rates histogram ", 
    "child_poverty" => "Child Poverty Count ",
    "gain_lose/ten_gl" => "Gain Lose by Tenure ",
    "gain_lose/dec_gl" => "Gain Lose by Decile ",
    "gain_lose/children_gl" => "Gain Lose by Number of Children ",
    "gain_lose/hhtype_gl" => "Gain Lose by Household Size ",
    "poverty_lines" => "Computed Poverty Lines ",
    "short_income_summary"=>"Short Income Summary ",
    "income_hists"=>"Histogram of Incomes ",
    "povtrans_matrix"=>"Poverty Transitions Matrix ",
    "examples"=>"Simple Worked Examples "
])

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