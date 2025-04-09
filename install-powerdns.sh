#!/bin/bash

clear
echo "🧠 PowerDNS + PowerAdmin (GUI) Installer para Ubuntu 24"
echo "====================================================="

# Input de dados
read -p "🌐 Qual o domínio da interface web (ex: dns.seudominio.com)? " WEB_DOMAIN
read -p "🔐 Senha para o banco de dados (usuário 'pdns'): " -s DB_PASS
echo ""
echo "⏳ Iniciando instalação... Isso pode levar alguns minutos."

# Atualiza pacotes
apt update && apt upgrade -y

# Instala MariaDB
apt install mariadb-server -y

# Cria DB e usuário
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

# Baixa e aplica schema do banco
wget -q https://raw.githubusercontent.com/PowerDNS/pdns/master/modules/gmysqlbackend/schema/schema.mysql.sql -O /tmp/schema.sql
mysql -u root powerdns < /tmp/schema.sql
rm /tmp/schema.sql

# Instala Apache + PHP + extensões
apt install apache2 php php-mysql php-mbstring php-xml php-intl php-curl unzip git -y

# Clona Poweradmin
cd /var/www/html
git clone https://github.com/poweradmin/poweradmin.git
chown -R www-data:www-data poweradmin

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
systemctl restart apache2

# (Opcional) Let's Encrypt
read -p "🔒 Deseja habilitar HTTPS com Let's Encrypt? [s/n]: " ENABLE_SSL
if [[ "$ENABLE_SSL" == "s" || "$ENABLE_SSL" == "S" ]]; then
  apt install certbot python3-certbot-apache -y
  certbot --apache -d ${WEB_DOMAIN}
fi

# Remove arquivos de instalação do Poweradmin
# rm -rf /var/www/html/poweradmin/install/

# Pega o IP da máquina
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Finalização
echo ""
echo "✅ Instalação finalizada com sucesso!"
echo "======================================"
echo "🌐 Acesse: http://${WEB_DOMAIN} (ou https se habilitou SSL)"
echo "🖥️ IP do servidor: ${IP_ADDRESS}"
echo "🔐 Banco de dados: powerdns"
echo "👤 Usuário DB: pdns"
echo "🔑 Senha DB: ${DB_PASS}"
echo ""
echo "🚨 Lembre-se de criar o registro A apontando ${WEB_DOMAIN} para ${IP_ADDRESS}"
echo "✅ Interface pronta para uso. Boa sorte!"
