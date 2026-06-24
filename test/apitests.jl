

import MicrosimAPIv1 as msa

# julia> sj = JSON3.write(msa.DEFAULT_MINI_PARAMS)
const JPS = """
{
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"child_benefit\":27.05,
    \"pension\":241.3,
    \"scottish_child_payment\":28.2,
    \"scp_age\":15,
    \"uc_single\":424.9,
    \"uc_taper\":55.0
}
"""

const UBIS = """
{
    \"abolished\":false,
    \"taxrates\":[19.0,20.0,21.0,42.0,45.0,48.0],
    \"taxbands\":[3967.0,16956.0,31092.0,62430.0,125140.0],
    \"nirates\":[0.0,0.0,8.0,2.0],
    \"nibands\":[129.0,242.0,967.0],
    \"taxallowance\":12570.0,
    \"abolish_uc\":true,
    \"abolish_sickness_bens\":false,
    \"abolish_jsa_esa\":true,
    \"abolish_pensions\":true,
    \"abolish_housing\":true,
    \"abolish_others\":true,
    \"ubi_as_mt_income\":true,
    \"ubi_taxable\":false,
    \"adult_amount\":4800.0,
    \"child_amount\":3000.0,
    \"universal_pension\":8780.0,
    \"adult_age\":17,
    \"retirement_age\":66
}
"""

@testset "JSON Tests" begin
    p1 = JSON3.read( JPS, msa.SimpleParams{Float64})
    # doesn't work because of the array see: https://discourse.julialang.org/t/define-equality-for-struct-by-checking-all-fields/121325
    # @test p1 == msa.DEFAULT_MINI_PARAMS["SimpleParams"]
    p2 = JSON3.read( UBIS, msa.UBIParams{Float64})
    # @test p2 == msa.DEFAULT_MINI_PARAMS["UBIParams"]
end

# from oxygen's testcases
@testset "formdata" begin
    req = Response("message=hello world&value=3")
    data = formdata(req)
    @test data["message"] == "hello world"
    @test data["value"] == "3"
end

@testset

# julia>
