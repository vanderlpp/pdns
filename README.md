# 🚀 PowerDNS + PowerAdmin Installer para Ubuntu 24

Este script instala e configura automaticamente o **PowerDNS Authoritative Server** com interface web **PowerAdmin**, usando **MariaDB** como backend.

Ideal para servidores de DNS autoritativo com gerenciamento remoto via interface web (GUI).

---

## ✅ Recursos

- Instalação automática e rápida
- Suporte ao domínio personalizado (ex: `dns.seudominio.com`)
- Interface web via **Apache2 + PHP**
- Integração com **Let's Encrypt (SSL opcional)**
- Backend em **MariaDB**
- Remove arquivos de instalação automaticamente
- Compatível com **Ubuntu 24.04**

---

## 📦 O que é instalado?

- PowerDNS Authoritative Server
- PowerAdmin (interface web)
- MariaDB Server (banco de dados)
- Apache2 + PHP
- Let's Encrypt (opcional)

---

## 🧪 Testado em:

- Ubuntu Server 24.04 (limpo)
- Ambiente Proxmox, VMware, VirtualBox

---

## 📥 Como usar

Execute o script diretamente com:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO/main/install-powerdns.sh)"
