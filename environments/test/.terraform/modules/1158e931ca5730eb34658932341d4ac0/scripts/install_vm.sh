sudo apt-get update
sudo apt-get install apache2 -y
sudo a2ensite default-ssl
sudo a2enmod ssl
sudo service apache2 restart
echo "\n\n >>> This instance of Apache running on $VM_NAME, hostname $HOSTNAME" | sudo tee /var/www/html/index.html
