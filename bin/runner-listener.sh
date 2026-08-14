julia --project=. --startup-file=no -t auto -e "import MicrosimAPIv1 as msa; msa.create_logger( \"listener-live\"); tasks = msa.create_scotben_queues(); wait.(tasks)"
