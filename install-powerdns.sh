#!/bin/bash

clear
echo "🚀 PowerDNS + PowerAdmin (GUI) Installer para Ubuntu 24"
echo "======================================================="

# Input de dados
read -p "🌐 Qual o domínio da interface web (ex: dns.seudominio.com)? " WEB_DOMAIN
read -p "🔐 Senha para o banco de dados (usuário 'pdns'): " -s DB_PASS
echo ""
echo "⏳ Iniciando instalação..."

# Atualiza pacotes
apt update && apt upgrade -y

# Instala MariaDB
apt install mariadb-server -y

# Cria banco e usuário
mysql -e "CREATE DATABASE powerdns;"
mysql -e "GRANT ALL ON powerdns.* TO 'pdns'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

# Instala PowerDNS
apt install pdns-server pdns-backend-mysql -y

# Configura PowerDNS
cat > /etc/powerdns/pdns.conf <<EOF
launch=gmysql
gmysql-host=127.0.0.1
gmysql-user=pdns
gmysql-password=${DB_PASS}
gmysql-dbname=powerdns
EOF

# Aplica schema do banco
wget -q https://raw.githubusercontent.com/PowerDNS/pdns/master/modules/gmysqlbackend/schema/schema.mysql.sql -O /tmp/schema.sql
mysql -u root powerdns < /tmp/schema.sql
rm /tmp/schema.sql

# Instala Apache + PHP + dependências do PowerAdmin
apt install apache2 php php-mysql php-mbstring php-xml php-intl php-curl unzip git composer -y

# Clona PowerAdmin
cd /var/www/html
rm -rf poweradmin
git clone https://github.com/poweradmin/poweradmin.git
cd poweradmin
composer install --no-dev --optimize-autoloader

# Permissões corretas
chown -R www-data:www-data /var/www/html/poweradmin
chmod -R 755 /var/www/html/poweradmin

# Gera config.inc.php
cat > /var/www/html/poweradmin/inc/config.inc.php <<EOF
<?php
\$db_host = 'localhost';
\$db_user = 'pdns';
\$db_pass = '${DB_PASS}';
\$db_name = 'powerdns';
\$db_type = 'mysql';
\$db_layer = 'PDO';
\$session_key = '$(openssl rand -hex 16)';
?>
EOF

# Configura Apache
cat > /etc/apache2/sites-available/${WEB_DOMAIN}.conf <<EOF
<VirtualHost *:80>
    ServerName ${WEB_DOMAIN}
    DocumentRoot /var/www/html/poweradmin

    <Directory /var/www/html/poweradmin>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${WEB_DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${WEB_DOMAIN}_access.log combined
</VirtualHost>
EOF

a2ensite ${WEB_DOMAIN}.conf
a2enmod rewrite
systemctl reload apache2

# HTTPS opcional
read -p "🔒 Deseja habilitar HTTPS com Let's Encrypt? [s/n]: " ENABLE_SSL
if [[ "$ENABLE_SSL" == "s" || "$ENABLE_SSL" == "S" ]]; then
  apt install certbot python3-certbot-apache -y
  certbot --apache -d ${WEB_DOMAIN}
fi

# Remove pasta install (seguro)
[ -d /var/www/html/poweradmin/install ] && rm -rf /var/www/html/poweradmin/install

# IP da máquina
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Fim
echo ""
echo "✅ Instalação finalizada com sucesso!"
echo "======================================"
echo "🌐 Interface disponível em: http://${WEB_DOMAIN}"
[ "$ENABLE_SSL" == "s" ] || [ "$ENABLE_SSL" == "S" ] && echo "🔐 HTTPS: https://${WEB_DOMAIN}"
echo "🖥️ IP do servidor: ${IP_ADDRESS}"
echo "🔐 Banco: powerdns | Usuário: pdns | Senha: ${DB_PASS}"
echo ""
