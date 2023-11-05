#!/bin/bash

# Define the base directory for home directories
base_dir="/var/www/home"

# Password for all users
password="Skills39"

# Create 10 users with home directories, enable HTTP basic auth, and create virtual hosts
for i in {01..10}; do
    username="user$i"
    home_dir="$base_dir/$username"
    domain="$username.malaka.id"
    index_file="$home_dir/index.html"
    htpasswd_file="/etc/apache2/.htpasswd_$username"

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping."
    else
        # Create the user and set the home directory
        useradd -m -d "$home_dir" -s /bin/bash "$username"
        
        # Set the password for the user
        echo "$username:$password" | chpasswd

        # Create the Apache virtual host configuration
        cat <<EOF > /etc/apache2/sites-available/$domain.conf
<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain
    DocumentRoot $home_dir
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory "$home_dir">
        Options Indexes FollowSymLinks
        AllowOverride All
        AuthType Basic
        AuthName "Restricted Content"
        AuthUserFile $htpasswd_file
        Require valid-user
    </Directory>
</VirtualHost>
EOF

        # Enable the virtual host
        a2ensite $domain

        # Create the index.html file
        echo "<html><h1>This is user website. The content is not yet changed</h1></html>" > $index_file

        # Create HTTP basic auth user file
        htpasswd -cb $htpasswd_file $username $password

        # Display a message
        echo "User $username created with home directory: $home_dir, password: $password, virtual host: $domain, and HTTP basic auth enabled."

    fi
done

# Reload Apache to apply the new configurations
systemctl reload apache2
