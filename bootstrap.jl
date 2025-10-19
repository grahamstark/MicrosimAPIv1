(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir
# Graham was here
using MicrosimAPIv1
const UserApp = MicrosimAPIv1
MicrosimAPIv1.main()
