# dist upgrades
apt-get -qq update
apt-get -qq -y upgrade

## git for composer and bc for math operations - vnstat for bandwidth
apt-get -y install git bc curl vnstat

# How much RAM does this computer even have? This will be in kilobytes
MEM_TOTAL=$( grep MemTotal /proc/meminfo | awk '{print $2}' )

# How much of that RAM should be set aside exclusively for Apache?
APACHE_MEM=$( echo "$MEM_TOTAL * 0.90 / 1" | bc  )

# MaxClients = Usable Memory / Memory per Apache process
MAX_CLIENTS=$(( $APACHE_MEM / $APACHE_PROCESS_MEM )) 


# LAMP setup
apt-get -qq -y install apache2 php libapache2-mod-php php-curl php-mbstring

# we need these mods
a2enmod status

# we don't need these mods. -f to avoid "WARNING: The following essential module will be disabled"
a2dismod -f deflate alias rewrite


## create a new configuration file and write our own
touch $CONF_FILE

echo "Writing to a configuration file $CONF_FILE...";

cat > $CONF_FILE <<EOL
ServerName localhost

<VirtualHost *:80>
	DocumentRoot /var/www/
</VirtualHost>

ServerLimit $MAX_CLIENTS

<IfModule mpm_prefork_module>
    StartServers        5
    MinSpareServers     5
    MaxSpareServers     10
    MaxClients          $MAX_CLIENTS
    MaxRequestsPerChild 0
</IfModule>

ExtendedStatus On

<Location /proxy-status>
	SetHandler server-status
</Location>

EOL


service apache2 restart
