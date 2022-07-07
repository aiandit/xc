#! /bin/bash

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

set -x

HOST=${HOST:-$(hostname)}

UMW_HOSTNAME=${UMW_HOSTNAME:-$HOST}
UMW_DOMAIN=${UMW_DOMAIN:-local}
UMW_HOSTNAME_GENERIC=${UMW_HOSTNAME}.${UMW_DOMAIN}
UMW_HOSTNAME_FQN=${UMW_HOSTNAME_FQN:-example.com}

export UMW_DOMAIN UMW_HOSTNAME UMW_HOSTNAME_GENERIC

mydir=$(readlink -f $(dirname $BASH_SOURCE)/..)

XC_HOME=$mydir

cd $XC_HOME

#
# configure uwsgi-emperor
#

#
# xc_uwsgi.ini: setup and install file
#

sed -e "s�/path/to/your/project�$XC_HOME�" $mydir/ci/xc_uwsgi.ini > xc_uwsgi.ini

sudo mkdir -p /etc/uwsgi-emperor/vassals
rm /etc/uwsgi-emperor/vassals/xc_uwsgi.ini
ln -sfT $mydir/xc_uwsgi.ini /etc/uwsgi-emperor/vassals/xc_uwsgi.ini


#
# configure nginx
#

#
# xc_nginx.conf: setup and install file
#

HOSTNAME=$(hostname -f)

sed -e "s�/path/to/your/project�$XC_HOME�" \
    -e "s/hostname.local/$UMW_HOSTNAME.$UMW_DOMAIN/" \
    -e "s/example.com/$UMW_HOSTNAME_FQN/" \
    -e "s;http://example;http://$UMW_HOSTNAME;" \
    $mydir/ci/xc_nginx.conf > xc_nginx.conf

ln -sfT $mydir/xc_nginx.conf /etc/nginx/sites-available/xc_nginx.conf

cp $mydir/ci/uwsgi_params $mydir/

cd /etc/nginx/sites-enabled && ln -sf ../sites-available/xc_nginx.conf

# ln -sfT $mydir/ci/xc.service /etc/systemd/system/xc.service


#
# /etc/xc/allowed_path.txt: install file
#

mkdir -p /etc/xc
echo "$mydir" > /etc/xc/allowed_path.txt
echo "/usr/share/fonts" >> /etc/xc/allowed_path.txt

#
# /etc/nginx/mime.types: add line to config file
#

nginx_mt_file=/etc/nginx/mime.types
nginx_mt=text/xml
if ! grep -E "$nginx_mt +xsl" $nginx_mt_file; then
    sed -i.bak -e "/text\/xml/ a \ \ \ \ $nginx_mt                            xsl;" $nginx_mt_file
fi


#
# prepare installation dir
#

chown www-data -R $mydir

#adduser www-data root
#chmod g+w $mydir
#chgrp root $mydir

cd $mydir/xc && ./manage.py migrate

sed -i -e 's/DEBUG = True/#DEBUG = True/' xc/settings.py
sed -i -e "s/'example.local'/'$UMW_HOSTNAME', '$UMW_HOSTNAME.$UMW_DOMAIN', '$UMW_HOSTNAME_GENERIC', '$UMW_HOSTNAME_GENERIC.$UMW_DOMAIN'/" xc/settings.py

if ! grep do_start_prepare /etc/init.d/uwsgi-emperor; then
    cat >> /etc/init.d/uwsgi-emperor <<EOF
#(ai-and-it) needed to set permissions properly
do_start_prepare() {
        # Create with correct permissions in advance as uwsgi with --daemonize creates it world write otherwise
        touch "\$PIDFILE"
}
EOF
    fi

systemctl daemon-reload
systemctl restart nginx
systemctl restart uwsgi-emperor
