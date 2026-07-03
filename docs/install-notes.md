```bash
adduser apiuser
sudo adduser apiuser
sudo vim /etc/group
sudo mkdir /opt/api
sudo chown apiuser:ve  /opt/api -R
sudo chmod 775 /opt/api -R
cd /opt/api
sudo mkdir julia
sudo cp -arf ~/.juliaup/* julia/
sudo mkdir package
cd package
git clone git@github.com:grahamstark/MicrosimAPIv1.git
```

start julia & run `Pkg.instantiate(".")`

    poss install juliahub for apiuser and copy that version to /opt/api/

# julia for user apiuser in dir /opt/api/julia/
sh juliaup.sh -p /opt/api/julia/

    permissions on /opt/api need reset after alomst everything ..

??? Make a package that imports MicrosimAPIv1 and use Pkg.update(".") rather than `git pull` ??
