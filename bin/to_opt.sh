sudo /bin/cp -arf /home/graham_s/julia/vw/MicrosimAPIv1 /opt/api/package/
sudo chown apiuser:ve /opt/api/package/ -R
sudo chmod 755 /opt/api/package/ -R
sudo systemctl restart microapi.service
sudo systemctl restart runner-listener.service