#!/bin/bash

set -e

find_dirs() {
  local current_dir="$1"
  local dynamic_addons=",mnt/repo/third"

  # Recursively call find_dirs for each subdirectory
  for sub_dir in "$current_dir"/*; do
    if [ -d "$sub_dir" ]; then
      if [ ! -f "$sub_dir/__manifest__.py" ]; then
        for dir in "$sub_dir"/*; do
          if [ -f "$dir/__manifest__.py" ]; then
            dynamic_addons="$dynamic_addons,$sub_dir"
            break
          fi
        done
      fi
    fi
  done

  echo "$dynamic_addons"
}

: ${DB_PASSWORD:=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)}
: ${ADDONS_PATH:=$(echo '/usr/lib/python3/dist-packages/odoo/enterprise,/mnt/repo/custom'$(find_dirs "/mnt/repo/third" | tr '\n' ',' | sed 's/,$//'))}

sed -s 's/^\(admin_passwd\s*=\s*\).*$/\1'$DB_PASSWORD'/' /etc/odoo/odoo.conf > /tmp/odoo.conf
sed -i 's#^\(addons_path\s*=\s*\).*#\1'$ADDONS_PATH'#' /tmp/odoo.conf

echo "DBPASSWORD: $DB_PASSWORD"

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

check_config "db_host"      "$HOST"
check_config "db_port"      "$PORT"
check_config "db_user"      "$USER"
check_config "db_password"  "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1