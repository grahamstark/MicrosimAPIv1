#!/bin/sh
# use with su apiuser -c "bin/api-updater.sh"
cd /opt/api/package/MicrosimAPIv1/
/opt/api/julia/bin/julia --project=. -t auto -c "using Pkg;Pkg.activate(".");Pkg.instantiate();Pkg.update()"

