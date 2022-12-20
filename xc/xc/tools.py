from django import forms

from django.core.mail import send_mail

from register.models import UserIP

import xc.settings

import importlib
import os
import sys

def load_from_file(modname):
#    class_inst = None
#    expected_class = 'MyClass'

    my_mod = importlib.import_module(modname)

#    if hasattr(py_mod, expected_class):
#        class_inst = getattr(py_mod, expected_class)()

    return my_mod
 #   return class_inst


dirmanModuleName = os.getenv('XC_DIRMAN', xc.settings.XC_DIRMAN if hasattr(xc.settings, 'XC_DIRMAN') else 'xc.dirman.dirman')
dirman = load_from_file(dirmanModuleName)

print(dirmanModuleName)
print(dir(dirman))
print(dirman.version)

import json

import os

def xmlesc(str):
    str = str.replace('<', '&lt;')
    str = str.replace('>', '&gt;')
    str = str.replace('&', '&amp;')
    return str

def xmlescname(str):
    str = str.replace('/', '_')
    return str

def dictxml(dict, name='dict'):
    if type(dict) == type({}):
        res = '<%s>' % name
        for (i,k) in enumerate(dict.keys()):
            r = '%s\n' % dictxml(dict[k], xmlescname(k))
            res = res + r
        res = res + ('</%s>' % name)
        return res
    elif type(dict) == type([]):
        res = '<%s>' % name
        for (i,k) in enumerate(dict):
            r = '%s\n' % dictxml(k, 'item')
            res = res + r
        res = res + ('</%s>' % name)
        return res
    else:
        return '<%s>%s</%s>' % (name, xmlesc('%s' % (dict,)), name)

def getCGIParam(cgiobj, params):
    res = {}
    for (i,k) in enumerate(params):
        r = cgiobj.getlist(k)
        if len(r) == 1:
            r = r[0]
        res[k] = r
    return res

def getAllCGI(cgiobj):
    allnames = cgiobj.keys()
    cgidict = getCGIParam(cgiobj, allnames)
#    print(cgidict)
    return cgidict

def get_ip(ip):
    try:
        userip = UserIP.objects.get(ip=ip)
    except:
        userip = UserIP(ip=ip)
        userip.save()
    return userip

class XCForm(forms.Form):
    method = 'POST'
    title = 'Xc'

    def to_xml_multiple(self, field):

        f = self[field]
        elemname = 'input'
        s = ''

        moreAttrs = ""
        moreClasses = ""
        fattrs = f.build_widget_attrs(f.field.subfield.widget.attrs)
        def mapValue(v):
            if type(v) == type(True):
                return int(v)
            else:
                return v
        moreAttrs = " " + " ".join([ '%s="%s"' % (k, mapValue(fattrs[k])) for k in fattrs if k != 'class' ])
        moreClasses = (" " + fattrs['class']) if 'class' in fattrs else ''

        fval = f.value() if f.value() is not None else []

        for (i, sval) in enumerate(fval):

            s += '<field>'
            auto_id = (self.auto_id % (field,)) + f'{i}'
            s += '<label for="%s">%s</label>\n' % (auto_id, xmlesc(f.label))
            value = ' value="%s"' % (xmlesc(str(sval)),)
            s += '<input id="%s" class="%s" name="%s"%s type="%s"%s/>' % (
                auto_id, f.css_classes() + moreClasses, f.name, moreAttrs, 'text', value)
            s += '</field>'

        for e in f.errors:
            s += self.renderError(f'path', e)

        return s


    def to_xml(self, field):
        f = self[field]
        elemname = 'input'
        try:
            ftype = f.field.widget.input_type
        except:
            ftype = 'textarea'
            elemname = 'textarea'
        if ftype == 'select':
            elemname = 'select'

        if ftype == 'multiple':
            return self.to_xml_multiple(field)

        auto_id = self.auto_id % (field,)
        s = '<field><label for="%s">%s</label>\n' % (auto_id, xmlesc(f.label))

        fval = f.value() if f.value() is not None else ''
        value = ''
        moreAttrs = ""
        moreClasses = ""
        fattrs = f.build_widget_attrs(f.field.widget.attrs)
        def mapValue(v):
            if type(v) == type(True):
                return int(v)
            else:
                return v
        moreAttrs = " " + " ".join([ '%s="%s"' % (k, mapValue(fattrs[k])) for k in fattrs if k != 'class' ])
        moreClasses = (" " + fattrs['class']) if 'class' in fattrs else ''
        if elemname == 'input':
            if ftype == 'checkbox':
                value = ' checked="1"' if fval else ''
            elif ftype == 'file':
                pass
            else:
                value = ' value="%s"' % (xmlesc(str(fval)),)
            s += '<input id="%s" class="%s" name="%s"%s type="%s"%s/></field>' % (
                auto_id, f.css_classes() + moreClasses, f.name, moreAttrs, ftype, value)
        elif elemname == 'select':
            if type(f.field.widget) == type(forms.SelectMultiple()):
                moreAttrs += ' multiple="multiple"'
            s += '<select id="%s" class="%s" name="%s"%s>\n' % (
                auto_id, f.css_classes() + moreClasses, f.name, moreAttrs)
            olist = [ '<option %svalue="%s">%s</option>' % ('selected="selected" ' if c in fval else '',
                                                            c, d) for (c, d) in f.form.fields[field].choices ]
            s += '\n'.join( olist )
            s += '</select></field>'
        else:
            s += '<textarea id="%s" class="%s" name="%s"%s><![CDATA[%s]]></textarea></field>' % (
                auto_id, f.css_classes() + moreClasses, f.name, moreAttrs, fval)
        return s

    def renderError(self, for_, err):
        return '<label class="error" for="%s" >%s</label>' % (for_, err)

    def asxml(self):
        elems = [ self.to_xml(f) for f in self.fields ]
        s = '\n  '.join(elems)
        s += '\n'
        s += '\n  '.join([ self.renderError(e, self.errors[e]) for e in self.errors ])
        s += '\n'
#        print('asxml', s)
        return s

siteDomain = 'example.com'
siteName = 'Xc'

def sendActivationEmail(to, actcode):
    from email.mime.text import MIMEText

    msgTxt = """
Hello,

someone, hopefully you, signed you up to Xc.

Please complete the registration by clicking on the link below

%s

or, alternatively fill in the activation code

%s

into the following form

%s

Cheers,
Your team @ Xc
"""

    actURLPlain = "https://%s/register/activate/" % (siteDomain,)
    actURL      = "%s?code=%s" % (actURLPlain, actcode)

    msgTxt = msgTxt % (actURL, actcode, actURLPlain)

    msg = MIMEText(msgTxt)

    subject = '%s User Registration' % siteName

#    print msg.as_string()

    sendEmail(to, xc.settings.DEFAULT_FROM_EMAIL, subject, msg)

def sendEmail(to, from_, subject, msg):

    msg['Subject'] = '%s Activation Code' % siteName
    msg['From'] = from_
    msg['To'] = to

    if xc.settings.EMAIL_HOST == 'example.com':
        print("Emails have not been configured")
        print(msg)
    else:
        send_mail(msg['Subject'], msg.get_payload(), msg['From'], [msg['To']])

def userdict(user):
#    print(user.is_authenticated)
#    print(type(user).__name__)
    if not user.is_authenticated:
        return dict( (key, getattr(user, key)) for key in ['username',
                                                           'is_authenticated', 'is_superuser'] )
    else:
        return dict( (key, getattr(user, key)) for key in ['username', 'email', 'first_name',
                                                           'last_name', 'last_login', 'date_joined',
                                                           'is_authenticated', 'is_superuser'] )
workdir_base = xc.settings.XC_WORKDIR

if xc.settings.XC_USE_GIT:
    workdir = dirman.GitDirManager(base=workdir_base)
else:
    workdir = dirman.DirManager(base=workdir_base)

os.environ['XC_WORKDIR'] = xc.settings.XC_WORKDIR

os.environ['HOME'] = xc.settings.XC_HOME if 'XC_HOME' in dir(xc.settings) else '/var/www'

diractions = [
    {'action': 'newdoc', 'name': 'New Document'},
    {'action': 'newdir', 'name': 'New Collection'},
    {'action': 'fileupload', 'name': 'Upload File'},
#    {'action': 'fileupload', 'name': 'Download Collection as File Archive'},
    {'action': 'move', 'name': 'Move'},
    {'action': 'find', 'name': 'Find'},
    {'action': 'runwhich', 'name': 'Run'}
]
fileactions = [
    {'action': 'view', 'name': 'View'},
    {'action': 'edit', 'name': 'Edit'},
    {'action': 'transform', 'name': 'Transform'},
    {'action': 'get', 'name': 'Download', 'class': 'xc-nocatch', 'urlstyle': 1},
    {'action': 'replace', 'name': 'Replace'},
    {'action': 'clone', 'name': 'Clone'},
    {'action': 'move', 'name': 'Move'},
    {'action': 'delete', 'name': 'Delete'},
    {'action': 'action', 'name': 'Execute', 'if': 'exec'}
]

def get_lsl(path):
    lsl = workdir.stat(path)
    if len(lsl['info']) == 0:
        actions = diractions
    elif lsl['info']['type'] == 'd':
        actions = diractions
    else:
        actions = fileactions
    return {'lsl': lsl, 'dir-actions': actions}
