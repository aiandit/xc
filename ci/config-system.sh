#! /bin/bash

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

set -x

mydir=$(readlink -f $(dirname $BASH_SOURCE)/..)

XC_HOME=$mydir

sed -e "s§/path/to/your/project§$XC_HOME§" $mydir/ci/xc_uwsgi.ini > xc_uwsgi.ini

sudo mkdir -p /etc/uwsgi/vassals
ln -sfT $mydir/xc_uwsgi.ini /etc/uwsgi/vassals/xc_uwsgi.ini


HOSTNAME=$(hostname -f)

sed -e "s§/path/to/your/project§$XC_HOME§" -e s/example.local/$HOSTNAME/    $mydir/ci/xc_nginx.conf > xc_nginx.conf

ln -sfT $mydir/xc_nginx.conf /etc/nginx/sites-available/xc_nginx.conf

cp $mydir/ci/uwsgi_params $mydir/

cd /etc/nginx/sites-enabled && ln -sf ../sites-available/xc_nginx.conf

ln -sfT $mydir/ci/xc.service /etc/systemd/system/xc.service

mkdir -p /etc/xc
echo "$mydir" > /etc/xc/allowed_path.txt
echo "/usr/share/fonts" >> /etc/xc/allowed_path.txt

#adduser www-data root
chmod g+w $mydir
chgrp root $mydir

nginx_mt=/etc/nginx/mime.types
if ! grep 'application/xml+xslt' $nginx_mt; then
    sed -i.bak -e '/text/xml/ a \ \ \ \ application/xml+xslt                  xsl;' /etc/nginx/mime.types
fi

cd $mydir/xc && ./manage.py migrate

sed -i -e 's/DEBUG = True/#DEBUG = True/' -e s/example.local/$HOSTNAME/ xc/settings.py

systemctl enable xc
systemctl start xc
systemctl restart nginx
