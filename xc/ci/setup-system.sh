#! /bin/bash

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

mydir=$(readlink -f $(dirname $BASH_SOURCE)/..)

XCERP_HOME=$mydir

sed -e "s§/path/to/your/project§$XCERP_HOME§" ci/xc_uwsgi.ini > xc_uwsgi.ini

ln -sfT $mydir/xc_uwsgi.ini /etc/uwsgi/vassals/xc_uwsgi.ini
