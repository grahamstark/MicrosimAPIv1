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
sudo cp etc/runner-listener.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start runner-listener.service
sudo systemctl status -n200 runner-listener.service
```

Likewise for etc/microapi.service:

```sh
sudo cp etc/microapi.service /usr/lib/systemd/system/
sudo systemctl daemon-reload

sudo systemctl stop microapi.service
sudo systemctl start microapi.service
sudo systemctl status -n200 microapi.service
```

Homedir for `apiuser` - this is getting painful..

    apiuser:x:1003:1003:API User,,,:/opt/api/:/bin/fish

```bash
chmod 775 bin/api-updater.sh 
su apiuser -c "bin/api-updater.sh"   
```

In `/opt/api` as `apiuser`:

mkdir `run` and `bin` at top-level
Julia update script `api_updater.sh` in `bin`

Directory structure for apiuser in `/opt/api/`:

    julia/ <- via juliaup. FIXME maybe .julia would be as good?
    package/MicrosimAPIv1 
    model-runs/  <- working dir for runs since /tmp/ might be blocked when starting from systemd. This is referenced as joinpath(homedir(),"run")
    api-logging/

TODO: make a script that creates all the files, sending `/opt/api` as an iterpolated variable.

Apache: redirect port to 9091 for no-revise version.

## Initialising the database

```sql
drop database microapi;
create database microapi;
\c microapi;
\i db/microapi.sql
```

.. then load default results and page descriptions:

```julia 

import MicrosimAPIv1 as msa
msa.initialise_database()

```

## Postgres

```bash
alias psqm="psql -h /var/run/postgresql/ -U postgres microapi"
```


In `pg_hba.conf`:
```
local   all             all                                     trust
``` 

## VM

Networking: Bridged Adapter

### On ROUTER

DMZ - add VM's address

Ethernet Gateway: add ports 22 and 80, IP of VM

### DNS 

    models.virtual-worlds.scot
    microapi.virtual-worlds.scot

both point to new VM on 137.220.123.248

### APACHE

* create `models.virtual-worlds.scot`  and `microapi.virtual-worlds.scot` 
* sudo en2mod proxy proxy_http rewrite 

### Julia

useradd apiuser 
su - apiuser


## NEW VM STUFF

```
sudo apt install snapd

sudo snap install --classic certbot

suddo /snap/bin/certbot

sudo a2enmod proxy proxy_http rewrite ssl headers

sudo apt install certbot

```

As apiuser

```
 
mkdir ~/api-logging
mkdir ~/model-runs

```
