#=
start the microapi job runner
version for systemd
Claude helped ...
=#
using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.update()

import MicrosimAPIv1 as msa
tasks = msa.create_scotben_queues(2)
wait.(tasks)
