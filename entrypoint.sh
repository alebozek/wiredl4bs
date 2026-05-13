#!/bin/bash
set -e

# configuracion para rsyslogd
sed -i '/imklog/d' /etc/rsyslog.conf
sed -i '/imklog/d' /etc/rsyslog.d/*.conf 2>/dev/null || true

mkdir -p /var/log
touch /var/log/auth.log /var/log/syslog
chmod 666 /var/log/auth.log /var/log/syslog

rm -f /run/rsyslogd.pid
rsyslogd -n &

# AIDE
if [ ! -f /var/lib/aide/aide.db ] && [ ! -f /var/lib/aide/aide.db.gz ]; then
    echo "[*] Primera ejecución: Inicializando AIDE..."
    aide --config /etc/aide/aide.conf --init
    mv /var/lib/aide/aide.db.new* /var/lib/aide/aide.db 2>/dev/null || \
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz 2>/dev/null || true
else
    echo "[*] Se ha encontrado la base de datos de AIDE, ejecutando comprobaciones de integridad..."
    aide --check --config /etc/aide/aide.conf >/dev/null 2>&1 || true
fi

echo "[*] AIDE listo"

# SERVICES
php-fpm8.1 &
/usr/sbin/sshd

exec /usr/local/apache2/bin/httpd -D FOREGROUND