from django.shortcuts import render

from django.contrib.auth.models import User

from xc.tools import *

from xc import settings

from main.views import workdir

import os, time

# Create your views here.

def mailbox(request, u1):
    bname = '/home/%s/Mail/%s' % (request.user, u1)
    return ('%s.xml' % (bname,), '%s-read.xml' % (bname,))

def appendmsg(request, u1, u2, data, own=0):
    errmsg = ''
    maildir = '/home/%s/Mail' % u1
    if not workdir.isdir(maildir):
        std = workdir.mkdir(maildir, {'user': request.user.username, 'comment': 'msg'})
        if std != 0:
            errmsg = 'maildir not created: "%s"' % (std)
        return (std, errmsg)

    path = os.path.join('/home/%s/Mail/%s.xml' % (u1, u2))
    data = '<msg>%s%s</msg>\n' % ('<own>1</own>' if request.user.username == u1 else '', data)
    stat = workdir.appenddoc(path, data.encode('utf8'), {'user': request.user.username, 'comment': 'msg'})
    if stat == 0:
        lsl = workdir.stat(path)
        #                fdata = workdir.getdoc(path).decode('utf8')
    else:
        errmsg = 'file append failed: "%s"' % (stat)
    return (stat, errmsg)

def msgsXML(request, touser):
    (path, rtm) = mailbox(request, touser)
    fdata = ''
    try:
        fdata = workdir.getdoc(path).decode('utf8')
    except:
        pass
    readdate = '<rtm>0</rtm>'
    try:
        readdate = workdir.getdoc(rtm).decode('ascii')
    except:
        pass

    xml = '<xc xmlns="http://ai-and-it.de/xmlns/2020/xc">'
    xml += '<class>msgs</class>'
    xml += '<cont><msgs>' + fdata + '</msgs>'
    xml += '<readdate>' + readdate + '</readdate></cont></xc>'

    workdir.replacedoc(rtm, ('<rtm>%.16g</rtm>' % time.time()).encode('ascii'),
                       {'user': request.user.username, 'comment': 'msg-read'})
    return xml


class SendData(XCForm):
    title = 'Send Message'
    name = 'send'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    to = forms.CharField(max_length=1024, label='To', widget=forms.HiddenInput)
    data = forms.CharField(required=False, max_length=1024000, label='Msg', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def send(request):
    context = {'xapp': 'msgs', 'view': 'send', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/xframe.html', context)

def ajax_send(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    fdata = ''

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST
    rdata = SendData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        to = cdata['to']
        return ajax_psend(request, to)

    dict = getAllCGI(reqDict)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    #    data = { **data, **get_lsl(path) }

    xcontext = {'xapp': 'msgs', 'view': 'sendmsg', 'cgi': dict, 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'xcontent_cdata': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def psend(request, to):
    context = {'xapp': 'msgs', 'view': 'send', 'cgij': xmlesc(json.dumps({'to':to})), 'data': [], 'number': 0}
    return render(request, 'common/xframe.html', context)

def ajax_psend(request, to):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    fdata = ''

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST
    rdata = SendData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data

    if request.method == "POST":
        fromuser = request.user.username
        data = cdata['data']
        data = data.replace('\r', '')
        data = '<time>%.16g</time><from>%s</from><to>%s</to><text>%s</text>\n' % (time.time(), fromuser, to, data)

        touser = User.objects.filter(username=to).first()
        if touser is None:
            errmsg = 'The user does not exist'
        else:
            (st1,e1) = appendmsg(request, fromuser, to, data)
            (st2,e2) = appendmsg(request, to, fromuser, data)
            if st1 == 0 and st2 == 0:
                xcontent = msgsXML(request, to)
            else:
                errmsg = 'file write failed: %s/%s "%s/%s"' % (st1,st2,e1,e2)
                fdata = ''
                xcontent = fdata

    elif request.method == 'GET':
        xcontent = msgsXML(request, to)

    dict = getAllCGI(reqDict)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    #    data = { **data, **get_lsl(path) }

    xcontext = {'xapp': 'msgs', 'view': 'sendmsg', 'cgi': dict, 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'xcontent_cdata': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")
