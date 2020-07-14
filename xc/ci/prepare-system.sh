#! /bin/sh

# https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html

aptitude install -y python3 python3-decorator nginx uwsgi-plugin-python3 uwsgi-emperor
python3 -m pip install Django==3.0.7
