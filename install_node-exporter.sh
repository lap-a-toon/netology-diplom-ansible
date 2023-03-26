wget https://github.com/prometheus/node_exporter/releases/download/v1.0.0/node_exporter-1.0.0.linux-amd64.tar.gz 
tar xvfz node_exporter-*.*-amd64.tar.gz
cd node_exporter-*.*-amd64
mkdir /etc/prometheus/node-exporter
cp -r ./* /etc/prometheus/node-exporter
chown -R prometheus:prometheus /etc/prometheus/node-exporter/