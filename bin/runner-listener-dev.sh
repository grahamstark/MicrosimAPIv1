julia --project=. --startup-file=no -t auto -e "using Revise; import MicrosimAPIv1 as msa; msa.create_logger( \"listener-dev\"); tasks = msa.create_scotben_queues(); wait.(tasks)"
