#!/bin/bash

clear
echo "🧨 Desinstalador PowerDNS + PowerAdmin para Ubuntu 24"
echo "======================================================"

read -p "🌐 Qual domínio foi usado na instalação? (ex: dns.seudominio.com): " WEB_DOMAIN
read -p "❗ Tem certeza que deseja REMOVER COMPLETAMENTE o PowerDNS, PowerAdmin e todos os dados? [s/N]: " confirm

if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
  echo "🚫 Cancelado pelo usuário."
  exit 1
fi

echo "⏳ Removendo serviços e pacotes..."

# Para serviços
systemctl stop pdns
systemctl stop apache2
systemctl stop mariadb

# Remove banco e usuário
mysql -e "DROP DATABASE IF EXISTS powerdns;"
mysql -e "DROP USER IF EXISTS 'pdns'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Remove pacotes
apt purge --autoremove -y pdns-server pdns-backend-mysql mariadb-server apache2 php php-* certbot python3-certbot-apache unzip git

# Remove arquivos
rm -rf /var/www/html/poweradmin
rm -f /etc/apache2/sites-available/${WEB_DOMAIN}.conf
rm -f /etc/apache2/sites-enabled/${WEB_DOMAIN}.conf
rm -rf /etc/letsencrypt/live/${WEB_DOMAIN}
rm -rf /etc/letsencrypt/archive/${WEB_DOMAIN}
rm -f /etc/letsencrypt/renewal/${WEB_DOMAIN}.conf
rm -rf /var/lib/mysql
rm -rf /var/log/apache2
rm -rf /var/log/mysql
rm -rf /var/log/pdns
rm -rf /etc/powerdns
rm -rf /etc/mysql
rm -f /etc/systemd/system/multi-user.target.wants/pdns.service

# Atualiza Apache
a2dissite ${WEB_DOMAIN}.conf 2>/dev/null
systemctl reload apache2 2>/dev/null

# Atualiza lista de pacotes
apt update

echo ""
echo "✅ PowerDNS, PowerAdmin e todos os componentes foram completamente removidos."
echo "🧼 Sistema limpo!"
