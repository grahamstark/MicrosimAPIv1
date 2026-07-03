#=
start the microapi job runner
version for systemd
Claude helped ...
=#
import MicrosimAPIv1 as msa

tasks = msa.create_scotben_queues()
wait.(tasks)
