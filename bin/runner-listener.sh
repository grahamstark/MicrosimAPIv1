julia --project=. --startup-file=no -t auto -e "import MicrosimAPIv1 as msa; tasks = msa.create_scotben_queues(); wait.(tasks)"
