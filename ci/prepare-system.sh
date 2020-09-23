#! /bin/sh

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

apt-get update

apt-get install aptitude

aptitude install -y python3 python3-decorator python3-brotli nginx uwsgi-plugin-python3 uwsgi-emperor
python3 -m pip install Django==3.1.1
