import MicrosimAPIv1 as msa
using Pkg
Pkg.update()

msa.doserve()
# or .. for dev version with Revise:
# msa.testserve()
