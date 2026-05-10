# Stage 1: Compilación de Apache vulnerable (2.4.49 - CVE-2021-41773)
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG APACHE_VERSION=2.4.49

# instalamos únicamente las dependencias de compilación necesarias para compilar la versión de Apache deseada
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget ca-certificates build-essential \
        libpcre3-dev libssl-dev \
        libapr1-dev libaprutil1-dev \
        libexpat1-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# descargamos, descomprimimos y compilamos nuestra versión de Apache
RUN cd /usr/src \
    && wget -q "https://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz" \
    && tar -xzf "httpd-${APACHE_VERSION}.tar.gz" \
    && cd "httpd-${APACHE_VERSION}" \
    && ./configure \
        --prefix=/usr/local/apache2 \
        --with-mpm=event \
        --enable-so --enable-cgi --enable-dir --enable-mime \
        --enable-rewrite --enable-auth-basic --enable-authn-file \
        --enable-authz-user --enable-authz-groupfile --enable-authz-host \
        --enable-access-compat --enable-alias --enable-unixd \
        --enable-authn-core --enable-authz-core --enable-setenvif \
        --enable-filter --enable-log-config \
        --enable-proxy --enable-proxy-fcgi \
    && make -j"$(nproc)" \
    && make install


# Stage 2: Creamos la imagen final del laboratorio
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
# definimos las credenciales del usuario sin privilegios
ARG HTPASSWD_USER=wiredl4bs
ARG HTPASSWD_PASSWORD=gewoonzo

# instalamos las dependencias y programas necesarios
RUN apt-get update && apt-get install -y --no-install-recommends \
        aide aide-common \
        apache2-utils \
        openssh-server \
        php8.1-fpm \
        python3 \
        ca-certificates \
        libpcre3 libssl3 \
        libapr1 libaprutil1 \
        libexpat1 \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# copiamos el binario de Apache compilado desde la stage anterior
COPY --from=builder /usr/local/apache2 /usr/local/apache2

# copiamos el código del blog, la configuración de Apache y de AIDE
COPY blog-php/ /var/www/html/
COPY apache-lab.conf /usr/local/apache2/conf/httpd.conf
COPY aide.conf /etc/aide/aide.conf

# copiamos el script de backup de posts (vector de escalada)
COPY backup_posts.py /usr/local/bin/backup_posts.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# configuramos el laboratorio
RUN \
    sed -ri 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php/*/fpm/pool.d/www.conf \
    \
    # creamos los directorios necesarios para el laboratorio
    && mkdir -p /var/www/html/posts /run/sshd /var/lib/aide /var/backups/posts \
    \
    # ajustamos permisos para que la aplicación pueda escribir en el directorio de posts
    && chown -R www-data:www-data /var/www/html/posts \
    \
    # actualizamos la ruta del fichero htpasswd en .htaccess
    && sed -ri \
        's|^AuthUserFile[[:space:]]+.*|AuthUserFile /var/www/html/restricted/users|' \
        /var/www/html/restricted/.htaccess \
    \
    # creamos las credenciales htpasswd para autenticación de Apache
    && htpasswd -bc /var/www/html/restricted/users \
        "${HTPASSWD_USER}" "${HTPASSWD_PASSWORD}" \
    && chown www-data:www-data /var/www/html/restricted/users \
    \
    # habilitamos autenticación por contraseña y acceso SSH
    && sed -ri \
        's/^#?PasswordAuthentication\s+.*/PasswordAuthentication yes/' \
        /etc/ssh/sshd_config \
    && sed -ri \
        's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' \
        /etc/ssh/sshd_config \
    \
    # creamos el usuario sin privilegios del laboratorio con su contraseña
    && useradd -m -s /bin/bash "${HTPASSWD_USER}" \
    && echo "${HTPASSWD_USER}:${HTPASSWD_PASSWORD}" | chpasswd \
    \
    # VECTOR DE ESCALADA
    # el usuario puede ejecutar el script de backup como root sin contraseña.
    # la vulnerabilidad está en que el script llama a os.system()
    # con BACKUP_TOOL (variable de entorno),
    # que sudo preserva gracias a SETENV en esta regla concreta.
    && printf 'wiredl4bs ALL=(root) NOPASSWD: SETENV: /usr/bin/python3 /usr/local/bin/backup_posts.py\n' > /etc/sudoers.d/backup_posts \
    && chmod 0440 /etc/sudoers.d/backup_posts \
    && chown root:root /usr/local/bin/backup_posts.py \
    && chmod 0755 /usr/local/bin/backup_posts.py

# exponemos HTTP y SSH
EXPOSE 80 22
ENTRYPOINT ["/entrypoint.sh"]