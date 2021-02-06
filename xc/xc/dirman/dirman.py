#! /usr/bin/env python3

import os, sys, time, shutil, subprocess, csv, io

from xc import settings

def fileexists(name):
    res = True
    try:
        os.lstat(name)
    except BaseException as ex:
#        print('error: file %s does not exist' % (name,))
#        print(ex)
        res = False
    return res

def filetypeLetter(stat):
    if os.path.stat.S_ISREG(stat.st_mode):
        return '-'
    elif os.path.stat.S_ISDIR(stat.st_mode):
        return 'd'
    elif os.path.stat.S_ISLNK(stat.st_mode):
        return 'l'
    else:
        return '?'

def filepermletters(stat):
    uperms = (stat.st_mode & 0x1C0) >> 6
    l1 = 'r' if uperms & 0x4 else '-'
    l2 = 'w' if uperms & 0x2 else '-'
    l3 = 'x' if uperms & 0x1 else '-'
    return l1 + l2 + l3

def isexec(stat):
    uperms = (stat.st_mode & 0x1C0) >> 6
    isex = (uperms & 0x1) > 0
    return 1 if isex else 0

#st_keys = [ f for f in dir(os.stat('/')) if f.startswith('st_') ]
#st_keys = [ 'st_mtime', 'st_size', 'st_mode' ]
st_keys = [ 'st_mtime', 'st_size' ]

def getfinfo(path, relpath, follow=True):
#    print('getfinfo', path, relpath)
    try:
        if follow:
            stat = os.stat(path)
        else:
            stat = os.lstat(path)
    except BaseException as ex:
        print('getfinfo exception: ', ex)
        return ({}, {})
    ftype = filetypeLetter(stat)
#    print('os.stat', stat)
    statdict = { v: getattr(stat, v) for v in st_keys }
    data = {'name': os.path.basename(relpath),
            'dir': os.path.dirname(relpath),
#            'fullpath': path,
            'path': relpath,
            'type': ftype,
#            'perms': filepermletters(stat),
            'exec': isexec(stat),
#            'stattxt': stat.__repr__(),
            'statdict': statdict
#            'stat': stat
    }
    return (data, stat)

def getlsl(path, relpath = '.', dironly=False):
    if relpath == '':
        relpath = '/'
#    print('getlsl', path, relpath)
    (si, stat) = getfinfo(path, relpath)
    res = { 'info': si }
    if len(si.keys()) > 0:
        ftype = si['type']
        if ftype == 'd':
            fnames = [ f.name for f in os.scandir(path) ]
            #            ftimes = [ f.stat().st_atime for f in os.scandir(path) ]
            #            sind = sorted(range(len(ftimes)), key=lambda k: ftimes[k], reverse=True if sort == 'descend' else False)
            #            fnames = [ fnames[k] for k in sind ]
            #            print("Sort %s index: %s, sorted list: %s" % (sort, sind, fnames))
            subinfos = [ getfinfo(os.path.join(path, f), os.path.join(relpath, f), False)[0] for f in fnames ]
            res['finfo'] = subinfos
    else:
        res
#    print(res)
    return res

def getlines(fname):
    res = []
    try:
        res = open(fname, 'r').read().splitlines()
    except BaseException as ex:
        print(ex)
        pass
    return res


class DirManager:

    base = '/tmp'

    uhome = os.environ['HOME'] if 'HOME' in os.environ else '/root'
    allowedPaths = getlines('%s/.config/xc/allowed-paths.txt' % (uhome,)) + \
        getlines('/etc/xc/allowed-paths.txt')

    dir = '.'

    def chroot(self, path):
        self.base = self.realpath(path)
        self.dir = '.'
        stat = os.chdir(self.getpath())
        return stat

    def chdir(self, path):
        self.dir = self.normalizepath(path)
        stat = os.chdir(self.getpath())
        return stat

    def realpath(self, path):
        rpath = os.path.realpath(self.getpath(path))
        return rpath

    def normalize_allowed_path(self, relbase):
        comps = relbase.split('/')
        res = []
        for (i,k) in enumerate(comps):
            if k == '.':
                pass
            elif k == '..':
                if len(res) > 0:
                    res = res[0:len(res)-1]
            elif k == '':
                pass
            else:
                res.append(k)
        return '/'.join(res)

    def do_cutpath(self, path, base, relbase):
        if path[0:len(base)] == base:
            res = path[len(base):]
        elif sum([ path[0:len(f)] == f for f in self.allowedPaths ]) > 0:
            res = self.normalize_allowed_path(relbase)
        else:
            res = None
            print('cutpath: "%s" (%s) is not under base "%s", nor in allowed paths' %( path, relbase, base))
#        print('cutpath: "%s","%s","%s" -> %s' %( path, base, relbase, res))
        return res

    def cutpath(self, path, relbase):
        rpath = self.do_cutpath(path, self.base, relbase)
        return rpath

    def normalizepath(self, path):
        rpath = self.cutpath(self.realpath(path), path)
        if rpath is not None:
            if len(rpath) > 0 and rpath[0] == '/':
                rpath = rpath[1:]
            elif len(rpath) > 1 and rpath[0:2] == './':
                rpath = rpath[2:]
        return rpath

    def getpath(self, rel=None):
        if rel is None:
            return os.path.join(self.base, self.dir)
        else:
            while len(rel) > 0 and rel[0] == '/':
                rel = rel[1:]
            return os.path.join(self.base, self.dir, rel)

    def stat(self, path):
        if self.normalizepath(path) is None:
            return {}
        info = getfinfo(self.getpath(path), path)[0]
        return {'info': info}

    def lsl(self, path, sort='ascend'):
        if self.normalizepath(path) is None:
            return {}
        info = getlsl(self.getpath(path), self.normalizepath(path))
        return info

    def mkdir(self, name):
        try:
            print('mkdir', name)
            os.makedirs(self.getpath(name))
            stat = 0
        except:
            stat = -1
        return stat

    def rmdir(self, name, rec=False):
        if rec:
            stat = shutil.rmtree(self.getpath(name))
        else:
            stat = os.rmdir(self.getpath(name))
        return stat

    def newdoc(self, name):
        file = open(self.getpath(name), 'w')
        file.close()
        stat = 0
        return stat

    def fileexists(self, name):
        res = True
        try:
            os.stat(self.getpath(name))
        except BaseException as ex:
            print('error: file %s does not exist' % (name,))
            print(ex)
            res = False
        return res

    def isdir(self, name):
        res = False
        try:
            stat = os.stat(self.getpath(name))
            if filetypeLetter(stat) == 'd':
                res = True
        except BaseException as ex:
            print('error: file %s does not exist' % (name,))
            print(ex)
            res = False
        return res

    def isfile(self, name):
        res = False
        try:
            stat = os.stat(self.getpath(name))
            if filetypeLetter(stat) == '-':
                res = True
        except BaseException as ex:
            print('error: file %s does not exist' % (name,))
            print(ex)
            res = False
        return res

    def replacedoc(self, name, doc, *moreArgs):
        stat = 0
        try:
            fpath = self.realpath(name)
            if fpath[0:len(self.base)] == self.base:
                file = open(self.getpath(name), 'wb')
            else:
                stat = 'path is outside of scope'
        except IsADirectoryError as ex:
            stat = 'path is a directory'
        except BaseException as ex:
            stat = str(ex)
            print('Failed to open file %s for writing: %s' % (name, ex))
        if stat == 0:
            file.write(doc)
            file.close()
        return stat

    def appenddoc(self, name, doc):
        stat = 0
        try:
            fpath = self.realpath(name)
            if fpath[0:len(self.base)] == self.base:
                file = open(self.getpath(name), 'ab')
            else:
                stat = 'path is outside of scope'
        except IsADirectoryError as ex:
            stat = 'path is a directory'
        except BaseException as ex:
            stat = str(ex)
        if stat == 0:
            file.write(doc)
            file.close()
        return stat

    def getdoc(self, name):
        file = open(self.getpath(name), 'rb')
        content = file.read()
        file.close()
        return content

    def getbytes(self, name):
        file = open(self.getpath(name), 'rb')
        content = file.read()
        file.close()
        return content

    def getlines(self, name):
        file = open(self.getpath(name), 'r', encoding='utf8')
        t0 = time.time()
#        print('Start reading file: %s' % name)
        content = ''
        try:
            content = file.read()
        except BaseException as ME:
            print('File read failed: %s, %s' % (name, ME))
        t1 = time.time()
#        print('File read: %s, %g s' % (name, t1 - t0))
        return content.split('\n')

    def nlines(self, name):
        return len(self.getlines(name))

    def head(self, name, n):
#        print('retrieve first %d lines of %s' % (n, name))
        return self.getlines(name)[0:n]

    def tail(self, name, n):
#        print('retrieve last %d lines of %s' % (n, name))
        lines = self.getlines(name)
        return (lines[-n:], len(lines))

    def range(self, name, m, n):
#        print('retrieve range %d-%d of lines of %s' % (m, n, name))
        return self.getlines(name)[m:n]

    def renamedoc(self, name1, name2):
        stat = 0
        try:
            os.rename(self.getpath(name1), self.getpath(name2))
        except BaseException as ex:
            stat = -1
            print('renamedoc:', ex)
        return stat

    def deletedoc(self, name):
        if self.normalizepath(name) is None:
            return -2
        try:
            os.remove(self.getpath(name))
            stat = 0
        except:
            stat = -1
        return stat

    def findcmd(self, name, pattern, path=True, sys=True, case=True):
        op = ('-path' if path else '-name') if case else ('-ipath' if path else '-iname')
        sdir = '%s/%s' % (self.base, self.normalizepath(name))
        if sys:
            args = ['-L']
        else:
            args = []
        args = args + [sdir, '-name', '.git', '-prune', '-o']
        args = args + [op, pattern, '-print']
        args.insert(0, 'find')
        return args

    def find(self, name, pattern, path=True, sys=True, case=True):
        args = self.findcmd(name, pattern, path, sys, case)
        p = runproc(args, self.getpath('/'), capture_output=True, encoding='utf8')
        sout = p.stdout.split('\n')
        sout = [ self.cutpath(f, f) for f in sout[0:len(sout)-1] ]
        return sout

    def findsort(self, name, pattern, path=True, sys=True, case=True):
        print('findsort')
        args = self.findcmd(name, pattern, path, sys, case)
        p2 = subprocess.Popen(('sort',), stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, encoding='utf8')
        p1 = subprocess.Popen(args, cwd=self.getpath('/'), stdout=p2.stdin,
                              stderr=subprocess.STDOUT, stdin=None)
        p1rc = p1.wait()
        p2.stdin.close()
        sout = p2.stdout.read().split('\n')
        p2rc = p2.wait()
        # print('findsort result:', p1rc, p2rc)
        sout = [ self.cutpath(f, f) for f in sout[0:len(sout)-1] ]
        return sout

    def which(self, name, pattern, path=None, sys=True):
        if path is None:
            path = '/' in pattern
        ftrans = self.find(name, pattern, path=path, sys=sys)
        if len(ftrans) > 0:
            ftrans = [ftrans[len(ftrans)-1]]
        return ftrans

    def execute(self, args, *moreArgs):
        p = runproc(args, self.getpath('/'))
        return p

    def pipe(self, args):
        p = runproc(args, self.getpath('/'), capture_output=True, encoding='utf8')
        return p

    def getlock(self, path):
        return getlock(self.getpath('%s.lock' % (path,)))

    def rellock(self, l):
        return rellock(l)

from decorator import decorator
import logging

def getlock(fname, Tmax=4, tries=40):
    myid = fname
    mypid = os.getpid()
    myidf = None
    for i in range(tries):
        if not fileexists(myid):
            try:
                myidf = open(myid, 'x')
            except:
                pass
            if myidf is not None:
                myidf.write('myid-%s-%d\n' % (myid, mypid,))
                break
        time.sleep(Tmax/tries)
    if myidf is None:
        print('Error: Could not obtain the lock file "%s" after %d' % (fname, tries,))
        return
    return (fname, myidf)

def rellock(t):
    t[1].close()
    os.remove(t[0])

def runproc(cmdlist, wdir, timelimit=60, **kw):
    if cmdlist[0] == 'git':
        myid = os.path.join(wdir, cmdlist[0] + '.lock')
        l = getlock(myid)
        if l is None:
            return
    t0 = time.time()
#    print('exec:', cmdlist)
    p = subprocess.run(cmdlist, cwd = wdir, **kw)
    stat = p.returncode
#    print(p)
    if stat != 0:
        logging.warn('%s subprocess failed on %s with %d', cmdlist[0], cmdlist.__repr__(), stat)
        logging.warn('%s', p.stderr)
    dt = time.time() - t0
    if dt > timelimit:
        logging.warn('%s took %d seconds', cmdlist.__repr__(), dt)
    else:
        logging.info('%s took %d seconds', cmdlist.__repr__(), dt)
    if cmdlist[0] == 'git':
        rellock(l)
    return p

def gitadd(wdir):
    runproc(['git', 'add', '.'], wdir)

def gitdiff(wdir):
    p = runproc(['git', 'diff', '--numstat', 'HEAD'], wdir, capture_output=True, encoding='utf8')
    sout = p.stdout
    return sout

def gitcommit(wdir, diffnumstat, srcfun, comment):
    reader_list = csv.DictReader(io.StringIO('nnl\tndl\tfname\n' + diffnumstat), delimiter='\t')
    rows = [ r for r in reader_list ]
    if len(rows) == 0:
        return
#    print(rows)

    nnls = [int(x['nnl']) if x['nnl'] != '-' else 0 for x in rows]
    ndls = [int(x['ndl']) if x['nnl'] != '-' else 0 for x in rows]
    fnames = [x['fname'] for x in rows]
#   print(nnls, ndls, fnames)

    gitHeadLine = 'XC %d/+%d/-%d %s %s V0.1' % (len(rows), sum(nnls), sum(ndls), srcfun, ', '.join(fnames))
    runproc(['git', 'commit',
             '-m', gitHeadLine,
             '-m', 'Comment: ' + comment['comment'],
             '-m', 'User: ' + comment['user'],
             '-m', 'Command: ' + srcfun,
             '-m', 'Changed files: ' + (', '.join(fnames)),
             '-m', 'XC 0.1'
    ], wdir)

@decorator
def gitlog(func, wdir=settings.XC_WORKDIR, *args, **kw):
#    print(args)
#    print(kw)
    result = func(*args, **kw)
    gitadd(wdir)
    sout = gitdiff(wdir)
    gitcommit(wdir, sout, func.__name__, args[len(args)-1])
    return result

class GitDirManager(DirManager):

    @gitlog()
    def chroot(self, path, comment):
        return super().chroot(path)

    @gitlog()
    def chdir(self, path, comment):
        return super().chdir(path)

    @gitlog()
    def deletedoc(self, path, comment):
        return super().deletedoc(path)

    @gitlog()
    def mkdir(self, path, comment):
        return super().mkdir(path)

    @gitlog()
    def rmdir(self, path, comment):
        return super().rmdir(path)

    @gitlog()
    def newdoc(self, path, comment):
        return super().newdoc(path)

    @gitlog()
    def replacedoc(self, path, cont, comment):
        return super().replacedoc(path, cont)

    @gitlog()
    def appenddoc(self, path, cont, comment):
        return super().appenddoc(path, cont)

    @gitlog()
    def renamedoc(self, path, newpath, comment):
        return super().renamedoc(path, newpath)

    @gitlog()
    def execute(self, args, comment):
        return super().execute(args)


if __name__ == "__main__":
    dm = DirManager()
    print(dm.stat('.'))
    dm.mkdir('test')
    dm.chdir('test')
    print(dm.stat('.'))
    dm.newdoc('test123.xml')
    dm.replacedoc('test123.xml', '<a/>')
    print(dm.stat('.'))
    dm.chdir('..')
    print(dm.stat('test'))
    dm.rmdir('test', rec=True)
