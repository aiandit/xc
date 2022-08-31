#! /bin/bash

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

set -x

DOMAIN=${1:-$(hostname)}
HOST=${HOST:-$(hostname)}

XC_HOSTNAME=${XC_HOSTNAME:-$DOMAIN}
XC_HOSTNAME_GENERIC=${XC_HOSTNAME_GENERIC:-$HOST}
XC_TDOMAIN=${XC_TDOMAIN:-local}

export XC_TDOMAIN XC_HOSTNAME XC_HOSTNAME_GENERIC

mydir=$(readlink -f $(dirname $BASH_SOURCE)/..)

XC_HOME=$mydir

sed -e "s§/path/to/your/project§$XC_HOME§" $mydir/ci/xc_uwsgi.ini > xc_uwsgi.ini

sudo mkdir -p /etc/uwsgi-emperor/vassals
rm /etc/uwsgi-emperor/vassals/xc_uwsgi.ini
ln -sfT $mydir/xc_uwsgi.ini /etc/uwsgi-emperor/vassals/xc_uwsgi.ini


HOSTNAME=$(hostname -f)

sed -e "s§/path/to/your/project§$XC_HOME§" \
    -e "s/example.local/$XC_HOSTNAME/" \
    -e "s/generic.local/$XC_HOSTNAME_GENERIC.$XC_TDOMAIN/" \
    -e "s/server_name example/server_name $XC_HOSTNAME/" \
    -e "s;http://example;http://$XC_HOSTNAME;" \
    $mydir/ci/xc_nginx.conf > xc_nginx.conf

ln -sfT $mydir/xc_nginx.conf /etc/nginx/sites-available/xc_nginx.conf

rm /etc/nginx/sites-enabled/default

cp $mydir/ci/uwsgi_params $mydir/

cd /etc/nginx/sites-enabled && ln -sf ../sites-available/xc_nginx.conf

# ln -sfT $mydir/ci/xc.service /etc/systemd/system/xc.service

mkdir -p /etc/xc
echo "$mydir" > /etc/xc/allowed_path.txt
echo "/usr/share/fonts" >> /etc/xc/allowed_path.txt

chown www-data -R $mydir

#adduser www-data root
#chmod g+w $mydir
#chgrp root $mydir

nginx_mt_file=/etc/nginx/mime.types
nginx_mt=text/xml
if ! grep -E "$nginx_mt +xsl" $nginx_mt_file; then
    sed -i.bak -e "/text\/xml/ a \ \ \ \ $nginx_mt                            xsl;" $nginx_mt_file
fi

cd $mydir/xc && ./manage.py migrate
res=$?
if [[ "$res" != 0 ]]; then
    exit $res
fi

sed -i -e 's/DEBUG = True/#DEBUG = True/' xc/settings.py
sed -i -e "s/'example.local'/'$XC_HOSTNAME', '$XC_HOSTNAME_GENERIC', '$XC_HOSTNAME_GENERIC.$XC_TDOMAIN'/" xc/settings.py

if ! grep do_start_prepare /etc/init.d/uwsgi-emperor; then
    cat >> /etc/init.d/uwsgi-emperor <<EOF
#(ai-and-it) needed to set permissions properly
do_start_prepare() {
        # Create with correct permissions in advance as uwsgi with --daemonize creates it world write otherwise
        touch "\$PIDFILE"
}
EOF
    fi

if ! [[ -f $XC_HOME/xc/local_settings.py ]]; then
    :
fi

systemctl daemon-reload
systemctl restart nginx
systemctl restart uwsgi-emperor
