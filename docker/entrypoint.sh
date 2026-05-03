#!/usr/bin/env bash
set -euo pipefail

: "${MOODLE_DBTYPE:=${MOODLE_DATABASE_TYPE:-mariadb}}"
: "${MOODLE_DBHOST:=${MOODLE_DATABASE_HOST:-moodle-db}}"
: "${MOODLE_DBNAME:=${MOODLE_DATABASE_NAME:-moodle}}"
: "${MOODLE_DBUSER:=${MOODLE_DATABASE_USER:-moodle}}"
: "${MOODLE_DBPASS:=${MOODLE_DATABASE_PASSWORD:-}}"
: "${MOODLE_DBPREFIX:=mdl_}"
: "${MOODLE_WWWROOT:=http://localhost}"
: "${MOODLE_DATAROOT:=/var/www/moodledata}"
: "${MOODLE_REVERSE_PROXY:=false}"
: "${MOODLE_SSL_PROXY:=true}"
: "${MOODLE_AUTO_INSTALL:=false}"
: "${MOODLE_LANG:=id}"
: "${MOODLE_SITE_FULLNAME:=E-Learning Nurul Hasanah}"
: "${MOODLE_SITE_SHORTNAME:=E-Learning}"
: "${MOODLE_ADMIN_USER:=admin}"
: "${MOODLE_ADMIN_EMAIL:=admin@example.test}"

if [ -z "${MOODLE_DBPASS:-}" ]; then
    echo "Missing required environment variable: MOODLE_DBPASS or MOODLE_DATABASE_PASSWORD" >&2
    exit 1
fi

mkdir -p "$MOODLE_DATAROOT"
chown -R www-data:www-data "$MOODLE_DATAROOT"

cat > /var/www/html/config.php <<'PHP'
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = getenv('MOODLE_DBTYPE') ?: (getenv('MOODLE_DATABASE_TYPE') ?: 'mariadb');
$CFG->dblibrary = 'native';
$CFG->dbhost = getenv('MOODLE_DBHOST') ?: (getenv('MOODLE_DATABASE_HOST') ?: 'moodle-db');
$CFG->dbname = getenv('MOODLE_DBNAME') ?: (getenv('MOODLE_DATABASE_NAME') ?: 'moodle');
$CFG->dbuser = getenv('MOODLE_DBUSER') ?: (getenv('MOODLE_DATABASE_USER') ?: 'moodle');
$CFG->dbpass = getenv('MOODLE_DBPASS') ?: (getenv('MOODLE_DATABASE_PASSWORD') ?: '');
$CFG->prefix = getenv('MOODLE_DBPREFIX') ?: 'mdl_';
$CFG->dboptions = [
    'dbpersist' => 0,
    'dbport' => getenv('MOODLE_DBPORT') ?: (getenv('MOODLE_DATABASE_PORT_NUMBER') ?: ''),
    'dbsocket' => getenv('MOODLE_DBSOCKET') ?: '',
    'dbcollation' => getenv('MOODLE_DBCOLLATION') ?: 'utf8mb4_unicode_ci',
];

$CFG->wwwroot = getenv('MOODLE_WWWROOT') ?: 'http://localhost';
$CFG->dataroot = getenv('MOODLE_DATAROOT') ?: '/var/www/moodledata';
$CFG->admin = getenv('MOODLE_ADMIN_PATH') ?: 'admin';
$CFG->directorypermissions = 02777;

if ((getenv('MOODLE_REVERSE_PROXY') ?: 'false') === 'true') {
    $CFG->reverseproxy = true;
}

if ((getenv('MOODLE_SSL_PROXY') ?: 'true') === 'true') {
    $CFG->sslproxy = true;
}

require_once(__DIR__ . '/lib/setup.php');
PHP

chown www-data:www-data /var/www/html/config.php

if [ "${1:-}" = "apache2-foreground" ] || [ "${1:-}" = "php" ] || [ "${1:-}" = "bash" ]; then
    echo "Waiting for Moodle database at $MOODLE_DBHOST..."

    for attempt in $(seq 1 60); do
        if mysqladmin ping -h"$MOODLE_DBHOST" -u"$MOODLE_DBUSER" -p"$MOODLE_DBPASS" --silent >/dev/null 2>&1; then
            break
        fi

        if [ "$attempt" -eq 60 ]; then
            echo "Database is not reachable after 60 attempts." >&2
            exit 1
        fi

        sleep 2
    done

    installed="$(
        mysql -h"$MOODLE_DBHOST" -u"$MOODLE_DBUSER" -p"$MOODLE_DBPASS" "$MOODLE_DBNAME" \
            --batch --skip-column-names \
            -e "SHOW TABLES LIKE '${MOODLE_DBPREFIX}config';" 2>/dev/null || true
    )"

    if [ -z "$installed" ] && [ "$MOODLE_AUTO_INSTALL" = "true" ]; then
        if [ -z "${MOODLE_ADMIN_PASSWORD:-}" ]; then
            echo "Missing required environment variable for auto install: MOODLE_ADMIN_PASSWORD" >&2
            exit 1
        fi

        echo "Installing Moodle database..."

        su -s /bin/sh www-data -c "php /var/www/html/admin/cli/install_database.php \
            --agree-license \
            --lang='${MOODLE_LANG}' \
            --fullname='${MOODLE_SITE_FULLNAME}' \
            --shortname='${MOODLE_SITE_SHORTNAME}' \
            --adminuser='${MOODLE_ADMIN_USER}' \
            --adminpass='${MOODLE_ADMIN_PASSWORD}' \
            --adminemail='${MOODLE_ADMIN_EMAIL}'"
    fi
fi

exec "$@"
