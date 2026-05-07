#!/usr/bin/env python3
#hace una copia de seguridad de los posts en /var/backups/posts/
#requiere permisos de superusuario para escribir en /var/backups/
import os
import sys
import shutil
import datetime
import subprocess

POSTS_DIR   = "/var/www/html/posts"
BACKUP_BASE = "/var/backups/posts"

# herramienta de compresión configurable por entorno.
# por defecto usa 'tar', pero puede sobreescribirse con BACKUP_TOOL.
# ej: BACKUP_TOOL=/usr/bin/gzip
COMPRESS_TOOL = os.environ.get("BACKUP_TOOL", "tar")


def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}")


def ensure_backup_dir(path):
    os.makedirs(path, exist_ok=True)


def backup_posts():
    today    = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    dest_dir = os.path.join(BACKUP_BASE, today)

    log("[+] Backing up posts...")
    ensure_backup_dir(dest_dir)

    if not os.path.isdir(POSTS_DIR):
        log(f"ERROR: posts directory not found: {POSTS_DIR}")
        sys.exit(1)

    # copiamos los ficheros de posts al directorio de backup
    copied = 0
    for fname in os.listdir(POSTS_DIR):
        src = os.path.join(POSTS_DIR, fname)
        if os.path.isfile(src):
            shutil.copy2(src, dest_dir)
            copied += 1

    log(f"[+] Copied {copied} post(s) to {dest_dir}")

    # verificamos la herramienta de compresión y creamos el archivo
    archive = f"{dest_dir}.tar.gz"
    log(f"[+] Compressing backup with: {COMPRESS_TOOL}")

    # os.system hereda el entorno del proceso llamante, incluyendo
    # cualquier PATH o variable modificada por el usuario
    ret = os.system(f"{COMPRESS_TOOL} -czf {archive} -C {BACKUP_BASE} {today}")

    if ret == 0:
        shutil.rmtree(dest_dir)
        log(f"[+] Backup completed: {archive}")
    else:
        log(f"[-] WARNING: Compression failed (code {ret}). Uncompressed backup on: {dest_dir}")

    # limpiamos backups con más de 7 días
    log("[+] Cleaning up older logs (>7 days)...")
    cutoff = datetime.datetime.now() - datetime.timedelta(days=7)
    for entry in os.listdir(BACKUP_BASE):
        full = os.path.join(BACKUP_BASE, entry)
        mtime = datetime.datetime.fromtimestamp(os.path.getmtime(full))
        if mtime < cutoff:
            if os.path.isdir(full):
                shutil.rmtree(full)
            else:
                os.remove(full)
            log(f"[+] Deleted older backup: {entry}")

    log("[+] End of the backup process.")


if __name__ == "__main__":
    backup_posts()