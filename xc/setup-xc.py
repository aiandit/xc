#!/usr/bin/env python3
"""Django's command-line utility for administrative tasks."""
import os
import sys

import xc.settings

from xc.dirman import dirman

def main():

    ofpath = xc.settings.XC_WORKDIR

    if not dirman.fileexists(ofpath):
        print('Create XC directory %s' % (ofpath,))
        dirman.runproc(['mkdir', '-p', ofpath], wdir='.')

    if len([ f for f in os.scandir(ofpath) ]) > 0:
        print('Error: XC directory %s is not empty' % (ofpath,))
        exit()

    dirman.runproc(['chown', '-R', 'www-data:staff', ofpath], wdir='.')
    dirman.runproc(['chmod', 'u+rwx,g+rs,g-w,o-rwx,o+t', ofpath], wdir='.')

    print('Running git init in %s' % (ofpath,))
    dirman.runproc(['sudo', '-u', 'www-data', 'git', 'init'], ofpath)

    cwd = os.path.realpath(os.curdir)

    print('Install sys link in %s' % (ofpath,))
    dirman.runproc(['ln', '-s', '%s/login/static' % (cwd,), 'sys'], ofpath)

    dirman.runproc(['sudo', '-u', 'www-data', 'git', 'add', '.'], ofpath)
    dirman.runproc(['sudo', '-u', 'www-data', 'git', 'commit', '-m', 'initial'], ofpath)


if __name__ == '__main__':
    main()
