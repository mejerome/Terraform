 #!/bin/bash
sudo yum update
sudo yum -y install httpd
systemctl start httpd.service
systemctl enable httpd.service
cat > /var/www/html/index.html <<EOF
<h1>Fa no s3 wagyimi...from $(hostname -f)</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF
