#!/bin/bash
set -e

# inicializamos AIDE en la primera ejecución (el volumen está vacío)
if [ ! -f /var/lib/aide/aide.db ] && [ ! -f /var/lib/aide/aide.db.gz ]; then
    echo "[*] Primera ejecución: Inicializando AIDE..."
    aide --config /etc/aide/aide.conf --init
    mv /var/lib/aide/aide.db.new* /var/lib/aide/aide.db 2>/dev/null || \
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz 2>/dev/null || true
else
    echo "[*] Se ha encontrado la base de datos de AIDE, ejecutando comprobaciones de integridad..."
    aide --check --config /etc/aide/aide.conf >/dev/null 2>&1 || true
fi

echo "[*] AIDE listo, dando paso al resto de servicios."

# levantamos PHP, SSH y Apache
php-fpm8.1 -D
/usr/sbin/sshd
exec /usr/local/apache2/bin/httpd -D FOREGROUND