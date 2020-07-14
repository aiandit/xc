from xc.dirman.dirman import runproc

import tempfile

def transform(xsl, xml, wdir):
    tf = tempfile.NamedTemporaryFile('w', delete=False)
    print(tf.name)

    cmd = ['xsltproc', '-o', tf.name, xsl, xml]
    print(cmd)
    p = runproc(cmd, wdir, capture_output=True, encoding='utf8')
    print(p)
    if p.returncode != 0:
        print('transform failed', cmd)
        return (-1, None, p.stdout, p.stderr)
    return (0, open(tf, 'rb').read(), p.stdout, p.stderr)
