#=
start the microapi job runner
version for systemd
Claude helped ...
=#
import MicrosimAPIv1 as msa
msa.create_logger( "listener-live")
tasks = msa.create_scotben_queues(2)
wait.(tasks)
