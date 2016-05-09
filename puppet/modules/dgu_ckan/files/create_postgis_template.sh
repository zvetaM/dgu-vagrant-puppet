#!/bin/sh

TMPL_NAME="template_postgis"

# TODO: add support for multiple/non-default clusters

#To je le za Debian
#PG_VERSION=$(pg_lsclusters --no-header | grep 5432 | awk '{ print $1 }')

#To je pa za CentOS
PG_VERSION=$(pg_config --version | awk '{ print $2 }' | head -c3) 
#echo $PG_VERSION

case "$PG_VERSION" in
'9.2')
PG_POSTGIS="/usr/pgsql-9.2/share/contrib/postgis-2.1/postgis.sql"
PG_SPATIAL_REF="/usr/pgsql-9.2/share/contrib/postgis-2.1/spatial_ref_sys.sql"
;;
*)
echo "No support for $PG_VERSION in $0"
exit 1
;;
esac

test -e $PG_POSTGIS || exit 1
test -e $PG_SPATIAL_REF || exit 1

cat << EOF | psql -d postgres -q
CREATE DATABASE $TMPL_NAME WITH template = template0 ENCODING='UTF8';
UPDATE pg_database SET datistemplate = TRUE WHERE datname = '$TMPL_NAME';
EOF

createlang plpgsql $TMPL_NAME
psql -q -d $TMPL_NAME -f $PG_POSTGIS || exit 1
psql -q -d $TMPL_NAME -f $PG_SPATIAL_REF || exit 1

# change ownership of the postgis tables from the home user
# to the user used by the database. This is needed for
# 'paster db clean' to work and the tests.
cat << EOF | psql -d $TMPL_NAME
GRANT ALL ON geometry_columns TO PUBLIC;
GRANT SELECT ON spatial_ref_sys TO PUBLIC;
ALTER TABLE geometry_columns OWNER TO $1;
ALTER TABLE spatial_ref_sys OWNER TO $1;
ALTER VIEW geography_columns OWNER TO $1;
VACUUM FREEZE;
EOF
