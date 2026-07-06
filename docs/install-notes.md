```bash
adduser apiuser
sudo adduser apiuser
sudo groupmod -U apiuser -a ve
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

```sh
sudo cp runner-listener.service /usr/lib/systemd/system/
sudo systemctl start runner-listener.service
sudo systemctl status -n200 runner-listener.service
```

Homedir for `apiuser` - this is getting painful..

    apiuser:x:1003:1003:API User,,,:/opt/api/:/bin/fish

```bash
chmod 775 bin/api-updater.sh 
su apiuser -c "bin/api-updater.sh"    
```