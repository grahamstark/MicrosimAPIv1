#=
start the microapi job runner
version for systemd
Claude helped ...
=#
import MicrosimAPIv1 as msa
using Pkg
Pkg.update()
tasks = msa.create_scotben_queues(2)
wait.(tasks)
