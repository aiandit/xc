from django.shortcuts import render, redirect

from django.http import HttpResponse, StreamingHttpResponse

from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User

from django.contrib.auth.decorators import login_required

from django.urls import reverse

from django.core.exceptions import ValidationError
from django import forms

from register.models import ActivationCode, UserIP, unsign_acode

from xc.tools import *

from xc import settings

from xc.dirman import xslt

import json, os, mimetypes, zipfile, csv, io, re, gzip, brotli

def home(request):
    context = {'xapp': 'main', 'view': 'home', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def index(request):
    context = {'xapp': 'main', 'view': 'home', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_home(request):
    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    homeview = 'view'
    homepath = 'config.xml'
    if 'XC_HOME_VIEW' in dir(settings):
        homeview = settings.XC_HOME_VIEW
    if 'XC_HOME_PATH' in dir(settings):
        homepath = settings.XC_HOME_PATH

    return redirect(reverse(f'main:ajax_{homeview}', args=(homepath,)))


def path(request):
    context = {'xapp': 'main', 'view': 'path', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

# https://stackoverflow.com/questions/898669/how-can-i-detect-if-a-file-is-binary-non-text-in-python#7392391
textchars = bytearray({7,8,9,10,12,13,27} | set(range(0x20, 0x100)) - {0x7f})
def is_binary_string(bytes):
    return bool(bytes.translate(None, textchars))

def is_binary_file(name):
    fdata = open(name, 'rb').read()
    return is_binary_string(fdata)


class PathData(XCForm):
    name = 'path'
    title = 'Path'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'
    method = 'GET'

    path = forms.CharField(required=False, max_length=1024, label='Path')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def ajax_index(request):
    return ajax_path(request)

def ajax_path(request):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = PathData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        path = cdata['path']

        lsl = workdir.lsl(path)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions
    }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

class NewdocData(XCForm):
    title = 'New Document'
    name = 'newdoc'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    newdoc = forms.CharField(max_length=1024, label='Name')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def newdoc(request):
    context = {'xapp': 'main', 'view': 'newdoc', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_newdoc(request):

    lsl = ''

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = NewdocData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        path = cdata['path']
        rdata = NewdocData(initial=reqDict)
    elif request.method == "POST":
        reqDict = request.POST
        rdata = NewdocData(reqDict)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            newdoc = cdata['newdoc']
            newpath = os.path.join(workdir.normalizepath(path), newdoc)
            lsl = workdir.newdoc(newpath, {'user': request.user.username, 'comment': cdata['comment']})
            print('Operation newdoc(%s,%s) returned: %d (type %s)' % (path, newdoc, lsl, type(lsl)))
            if lsl != 0:
                errmsg = 'New doc creation failed'
            else:
                return redirect(reverse('main:ajax_path') + '?path=%s' % newpath)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'status': lsl,
        'errs': errors
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")



class MultiValueValidationError(ValidationError):
    # def __init__(self, errors):
    #     clean_errors = [
    #         f"{err.error_list[0]} ({name} item {key})" for err, name, key, value in errors
    #     ]
    #     for e, name, key, value in errors:
    #         print(f'error: {type(e.error_list[0])} {e.error_list[0].error_list[0]}')
    #     super().__init__(','.join(clean_errors))
    #     self.error_detail = errors
    def __init__(self, errors):
        super().__init__(errors)

class MultiValueFieldWidget(forms.widgets.Input):
    def __init__(self, pname):
        super().__init__()
        self.pname: str = pname
        self.input_type = 'multiple'
    def value_from_datadict(self, data, *args):
        return data.getlist(self.pname)

class MultiValueField(forms.Field):
    def __init__(self, subfield, pname, *args, **kw):
        super().__init__(widget=MultiValueFieldWidget(pname), *args, **kw)
        self.subfield = subfield
    def clean(self, values):
        if len(values) == 0 and self.required:
            raise ValidationError(self.error_messages["required"])
        result = []
        errors = []
        for i, value in enumerate(values):
            try:
                result.append(self.subfield.clean(value))
            except ValidationError as e:
                errors.append(e)
        if len(errors):
            raise MultiValueValidationError(errors)
        return result


class DeleteData(XCForm):
    name = 'delete'
    title = 'Delete'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = MultiValueField(forms.CharField(max_length=1024, label='File name', widget=forms.TextInput(attrs={'size': 120})), 'path', label='File name')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)
    confirm = forms.BooleanField(required=False, initial=True, widget=forms.HiddenInput)

    next_ = forms.CharField(required=False, max_length=1024, label='Follow-up action', widget=forms.HiddenInput)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def delete(request):
    context = {'xapp': 'main', 'view': 'delete', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_delete(request):

    errmsg = ''
    errors = []

    def doDelete(path):
        lsl = workdir.deletedoc(path, {'user': request.user.username, 'comment': cdata['comment']})
        print(f'delete {path}: {lsl}')
        return lsl

    def doMultiDelete(paths):
        lsl = 0
        for path in paths:
            lsl = doDelete(path)
            if lsl != 0:
                break
        return lsl

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = DeleteData(reqDict)
    path = None

    if not rdata.is_valid():
        errmsg = 'The form data is invalid'
    else:

        cdata = rdata.cleaned_data
        path = cdata['path']
        confirm = cdata['confirm']

        if confirm:
            lsl = 1
            if path:
                lsl = doMultiDelete(path)
            if lsl != 0:
                errmsg = 'doc deletion failed'
            else:
                next_ = cdata['next_']
                if len(next_) == 0:
                    next_ = redirect(reverse('main:ajax_path') + '?path=%s' % os.path.dirname(path))
                return redirect(next_)
        else:
            cdata.update({'confirm': 1})
            rdata = DeleteData(initial=cdata)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata ] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class NewdirData(XCForm):
    title = 'New Collection'
    name = 'newdir'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    newdir = forms.CharField(max_length=1024, label='Name')
    comment = forms.CharField(required=False, max_length=1024, label='Comment')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def newdir(request):
    context = {'xapp': 'main', 'view': 'newdir', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_newdir(request):

    lsl = ''

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = NewdirData(reqDict)

    if request.method == "GET":
        res = rdata.is_valid()
        if res:
            cdata = rdata.cleaned_data
            path = cdata['path']
            rdata = NewdirData(initial=cdata)
        else:
            cdata = {}
            path = '/'
            rdata = NewdirData(initial=reqDict)

    elif request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            newdir = cdata['newdir']

            newpath = os.path.join(workdir.normalizepath(path), newdir)
            lsl = workdir.mkdir(newpath, {'user': request.user.username, 'comment': cdata['comment']})
            print('Operation mkdir(%s,%s) returned: %d (type %s)' % (path, newdir, lsl, type(lsl)))
            if lsl != 0:
                errmsg = 'New collection creation failed'
            else:
                return redirect(reverse('main:ajax_path') + '?path=%s' % newpath)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

zoomscales = [10, 50, 65, 80, 90, 100, 120, 150, 200, 400]

class ControlForm(XCForm):
    name = 'view'
    title = 'XC View Document'
    path = forms.CharField(required=False, max_length=1024, label='Path')
    mode = forms.ChoiceField(required=False, choices=[('html', 'HTML'), ('svg', 'SVG')], label='Mode')
    zoom = forms.ChoiceField(required=False, choices=[('%d' % s, '%d %%' % s) for s in zoomscales], label='Zoom', initial='80')

class ViewData(PathData):
    name = 'view'
    title = 'XC View Document'
    mode = forms.CharField(required=False, max_length=1024, label='Mode')

def view_view(request, path=''):
    context = {'xapp': 'main', 'view': 'view', 'path': path, 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)


def ajax_view(request, path=None):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    mode = ''

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = ViewData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']
        mode = cdata['mode']

        lsl = workdir.stat(path)

        if lsl['info']['type'] == '-':
            (isXML, stat, fdata, fstr) = getxmlifposs(path)
            if isXML:
                xcontent = fstr
            else:
                content = fstr

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    if lsl['info']['type'] == 'd':
        actions = diractions
    else:
        actions = fileactions

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions,
        'viewmode': mode
    }
    xcontext = {'xapp': 'main', 'view': 'view', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata, ControlForm() ], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class EditData(XCForm):
    title = 'Edit'
    name = 'edit'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(max_length=1024, label='Path')
    data = forms.CharField(required=False, max_length=1024000, label='Content', widget=forms.Textarea)
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)
    next_ = forms.CharField(required=False, max_length=1024, label='Follow-up action')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def view_edit(request, path=''):
    context = {'xapp': 'main', 'view': 'edit', 'path': path, 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_edit(request, path=None):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    fdata = ''
    mtype = ''

    if request.method == "GET":
        reqDict = request.GET

    elif request.method == "POST":
        reqDict = request.POST

    rdata = EditData(reqDict)

    resultview = 'dirmanform'
    next_ = None

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']
        formpath = path

        if request.method == "POST":
            data = cdata['data']

            stat = workdir.replacedoc(path, data.encode('utf8'), {'user': request.user.username, 'comment': cdata['comment']})
            if stat == 0:
                lsl = workdir.stat(path)
                #                fdata = workdir.getdoc(path).decode('utf8')
                fdata = data
                next_ = cdata['next_']
                if len(next_) == 0:
                    next_ = reverse('main:ajax_edit') + '?path=%s' % (path,)
                return redirect(next_)

            else:
                errmsg = f'file write "{path}" failed: {stat}'
                fdata = ''
            xcontent = fdata

        elif request.method == 'GET':
            fdata = workdir.getdoc(path)
            (filename, file_extension) = os.path.splitext(path)
            mtype = mimetypes.guess_type(path)[0]
            if is_binary_string(fdata):
                errmsg = 'File is binary'
                formpath = os.path.dirname(path)
            else:
                try:
                    xcontent = fdata.decode('utf-8')
                except:
                    errmsg = 'File cannot be decoded as UTF8'
                    pass

        rdata = EditData(initial={'path': formpath})

    dict = getAllCGI(reqDict)
    dict['data'] = ''

    if len(errmsg):
        print('errmsg:', errmsg)
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }

    xcontext = {'xapp': 'main', 'view': resultview, 'cgi': dict, 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata, ControlForm()], 'xcontent_cdata': xmlesc(xcontent), 'mimetype': mtype}
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def append(request):
    context = {'xapp': 'main', 'view': 'append', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_append(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    path = ''
    fdata = ''
    mtype = ''

    if request.method == "GET":
        reqDict = request.GET

    elif request.method == "POST":
        reqDict = request.POST

    rdata = EditData(reqDict)

    resultview = 'dirmanform'
    next_ = None

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        path = cdata['path']
        formpath = path

        if request.method == "POST":
            data = cdata['data']

            data.replace('\n', '<br/>')

            stat = workdir.appenddoc(path, data, {'user': request.user.username, 'comment': cdata['comment']})
            if stat == 0:
                lsl = workdir.stat(path)
                #                fdata = workdir.getdoc(path).decode('utf8')
                fdata = data
                next_ = cdata['next_']
                if len(next_) == 0:
                    next_ = reverse('main:ajax_edit') + '?path=%s' % (path,)
                return redirect(next_)

            else:
                errmsg = f'file write "{path}" failed: {stat}'
                fdata = ''
            xcontent = fdata

        elif request.method == 'GET':
            fdata = workdir.getdoc(path)
            (filename, file_extension) = os.path.splitext(path)
            mtype = mimetypes.guess_type(path)[0]
            if is_binary_string(fdata):
                errmsg = 'File is binary'
                formpath = os.path.dirname(path)
            else:
                try:
                    xcontent = fdata.decode('utf-8')
                except:
                    errmsg = 'File cannot be decoded as UTF8'
                    pass

        rdata = EditData(initial={'path': formpath})

    dict = getAllCGI(reqDict)
    dict['data'] = ''

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }

    xcontext = {'xapp': 'main', 'view': resultview, 'cgi': dict, 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata, ControlForm()], 'xcontent_cdata': xmlesc(xcontent), 'mimetype': mtype}
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class FileuploadData(XCForm):
    title = 'Upload'
    name = 'fileupload'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
#    encoding = forms.CharField(required=False, max_length=1024, label='Encoding', initial='utf8')
    file = forms.FileField()
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def fileupload(request):
    context = {'xapp': 'main', 'view': 'fileupload', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_fileupload(request):

    lsl = ''

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = FileuploadData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        rdata = FileuploadData(initial=reqDict)
    elif request.method == "POST":
        reqDict = request.POST
        rdata = FileuploadData(reqDict, request.FILES)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            file = request.FILES['file']
            fdata = file.read()

            if not workdir.fileexists(path):
                errmsg = 'Path does not exist'
            else:
                if workdir.isdir(path):
                    newdoc = file.name
                    npath = os.path.join(workdir.normalizepath(path), newdoc)
                else:
                    npath = workdir.normalizepath(path)

                print('Upload:', file)

                lsl = workdir.replacedoc(npath, fdata, {'user': request.user.username, 'comment': cdata['comment']})
                print('Operation replacedoc(%s,<file(%dB)>) returned: %d (type %s)' % (npath, len(fdata), lsl, type(lsl)))
                if lsl != 0:
                    errmsg = 'File upload failed'
                else:
                    return redirect(reverse('main:ajax_path') + '?path=%s' % path)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    path = cdata['path']
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def replace(request):
    return fileupload(request)

def ajax_replace(request):
    return ajax_fileupload(request)


class MoveData(XCForm):
    title = 'Move'
    name = 'move'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(max_length=1024, label='Path')
    newpath = forms.CharField(max_length=1024, label='New path')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def move(request):
    context = {'xapp': 'main', 'view': 'move', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_move(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    fdata = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = MoveData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        rdata = MoveData(initial=cdata)

    elif request.method == "POST":
        reqDict = request.POST
        rdata = MoveData(reqDict)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            newpath = cdata['newpath']

            base = os.path.dirname(path)
            fname = os.path.basename(path)
            if newpath[0] == '/':
                newbase = newpath
            else:
                newbase = os.path.join(base, newpath)

            if workdir.isdir(newbase):
                outpath = os.path.join(newbase, fname)
            else:
                outpath = newbase

            stat = workdir.renamedoc(path, outpath, {'user': request.user.username, 'comment': cdata['comment']})
            if stat == 0:
                return redirect(reverse('main:ajax_path') + '?path=%s' % base)
            else:
                errmsg = f'file write "{path}" failed: {stat}'
                fdata = ''

    path = cdata['path']

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = fdata

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors,
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def docToNewDoc(path, newpath, newcont, info):
    base = os.path.dirname(path)
    fname = os.path.basename(path)
    if newpath[0] == '/':
        newbase = newpath
    else:
        newbase = os.path.join(base, newpath)

    if workdir.isdir(newbase):
        outpath = os.path.join(newbase, fname)
    else:
        outpath = newbase

    stat = workdir.replacedoc(outpath, newcont, info)
    return (stat, outpath)


class CloneData(XCForm):
    title = 'Clone'
    name = 'clone'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(max_length=1024, label='Path')
    newpath = forms.CharField(max_length=1024, label='New path')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def clone(request):
    context = {'xapp': 'main', 'view': 'clone', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_clone(request):

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    fdata = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = CloneData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        rdata = CloneData(initial=cdata)

    elif request.method == "POST":
        reqDict = request.POST
        rdata = CloneData(reqDict)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            newpath = cdata['newpath']

            (stat, outpath) = docToNewDoc(path, newpath, workdir.getbytes(path),
                                          {'user': request.user.username, 'comment': cdata['comment']})
            if stat == 0:
                return redirect(reverse('main:ajax_path') + '?path=%s' % outpath)
            else:
                errmsg = f'file write "{path}" failed: {stat}'
                fdata = ''

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = fdata

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions

    data = {
        'errs': errors
    }
    path = cdata['path']
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class TransformData(XCForm):
    title = 'Transform'
    name = 'transform'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(max_length=1024, label='Path')
    transform = forms.CharField(max_length=1024, label='Transformation')
    newpath = forms.CharField(max_length=1024, label='New path')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def transform(request):
    context = {'xapp': 'main', 'view': 'transform', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_transform(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    fdata = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = TransformData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        rdata = TransformData(initial=cdata)

    elif request.method == "POST":
        reqDict = request.POST
        rdata = TransformData(reqDict)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            newpath = cdata['newpath']
            transform = cdata['transform']

            ftrans = workdir.find('/', transform)
            print(ftrans)
            if len(ftrans) == 0:
                errmsg = 'Transformation not found'
                rdata.add_error("transform", 'Transformation not found')
            else:
                ftrans = ftrans[len(ftrans)-1]
                result = xslt.transform(workdir.getpath(ftrans), workdir.getpath(path), workdir.base)
                if result[0] != 0:
                    errors.append({'errmsg': 'Transformation failed', 'type': 'fatal', 'details': result[3]})
                else:
                    (stat, outpath) = docToNewDoc(path, newpath, result[1],
                                                  {'user': request.user.username, 'comment': cdata['comment']})
                    if stat == 0:
                        return redirect(reverse('main:ajax_path') + '?path=%s' % outpath)
                    else:
                        errmsg = f'file write "{path}" failed: {stat}'
                        fdata = ''

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = fdata

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions

    data = {
        'errs': errors
    }
    path = cdata['path']
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class WhichData(XCForm):
    title = 'Which'
    name = 'which'
    method = 'get'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    which = forms.CharField(max_length=1024, label='Pattern')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def which(request):
    context = {'xapp': 'main', 'view': 'which', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_which(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    findlist = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = WhichData(reqDict)
        res = rdata.is_valid()

    elif request.method == "POST":
        reqDict = request.POST
        rdata = WhichData(reqDict)
        res = rdata.is_valid()

    cdata = rdata.cleaned_data

    if not res:
        errmsg = 'The form data is invalid'
    else:
        print(cdata)
        path = cdata['path']
        which = cdata['which']

        findlist = mkfindlist(workdir.which('/', which))
        if len(findlist) == 0:
            errmsg = 'File not found'
            rdata.add_error("which", 'File not found')

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = ''

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions,
        'findlist': findlist
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class RunwhichData(XCForm):
    name = 'runwhich'
    title = 'Run'
    method = 'get'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    which = forms.CharField(max_length=1024, label='Pattern')
    choices=[ (f.lower(), f) for f in ['View', 'Edit', 'Clone', 'Transform', 'Get'] ]
#    print('choices', choices)
    action = forms.ChoiceField(label='Action',
                               choices=choices,
                               widget=forms.Select(choices=choices))

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def runwhich(request):
    context = {'xapp': 'main', 'view': 'runwhich', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_runwhich(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    findlist = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = RunwhichData(reqDict)
        res = rdata.is_valid()

    elif request.method == "POST":
        reqDict = request.POST
        rdata = RunwhichData(reqDict)
        res = rdata.is_valid()

    cdata = rdata.cleaned_data

    if not res:
        errmsg = 'The form data is invalid'
    else:
        print(cdata)
        path = cdata['path']
        which = cdata['which']
        action = cdata['action']
        if 'submit' in reqDict:
            findlist = mkfindlist(workdir.which('/', which))
            if len(findlist) == 0:
                errmsg = 'File not found'
                rdata.add_error("which", 'File not found')
            else:
                print(findlist)
                return redirect(reverse('main:ajax_' + action) + '?path=%s/%s' % (findlist[0]['path'], findlist[0]['name']))

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = ''

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions,
        'findlist': findlist
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class GetfData(XCForm):
    name = 'getf'
    title = 'Get File'
    method = 'get'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    which = forms.CharField(max_length=1024, label='Pattern')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def getf(request):
    context = {'xapp': 'main', 'view': 'getf', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_getf(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    findlist = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = GetfData(reqDict)
        res = rdata.is_valid()

    elif request.method == "POST":
        reqDict = request.POST
        rdata = GetfData(reqDict)
        res = rdata.is_valid()

    cdata = rdata.cleaned_data

    if not res:
        errmsg = 'The form data is invalid'
    else:
        which = cdata['which']
        if 'submit' in reqDict:
            findlist = mkfindlist(workdir.which('/', which))
            if len(findlist) == 0:
                errmsg = 'File not found'
                rdata.add_error("which", 'File not found')
            else:
                #print('getf: %s -> %d results ' %(which, len(findlist)))
                path = '%s/%s' % (findlist[0]['path'], findlist[0]['name'])
                #print('getf: %s -> %s ' %(which, path))
                return getp(request, path)

    (filename, file_extension) = os.path.splitext(path)
    xcontent = ''
    content = ''

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions,
        'findlist': findlist
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def getfp(request, pattern):

    errors = []

    which = '*/' + pattern
    findlist = mkfindlist(workdir.which('/', which))
    if len(findlist) == 0:
        errmsg = 'getfp: File ''%s'' not found' % (pattern,)
        print(errmsg)
    else:
        #print('getfp: %s -> %d results ' % (which, len(findlist)))
        path = '%s/%s' % (findlist[0]['path'], findlist[0]['name'])
        #print('getfp: %s -> %s ' %(which, path))
        return getp(request, path)

    return HttpResponse(status=404)

def getxmlifposs(path):
    lsl = workdir.stat(path)
    if lsl is None or len(lsl) == 0 or len(lsl['info']) == 0 or lsl['info']['type'] != '-':
        return (False, lsl, '', '')

    fdata = workdir.getdoc(path)
    isXML = False
    fstr = ''
    try:
       Npdata = 128
       if Npdata > lsl['info']['statdict']['st_size']:
           Npdata = lsl['info']['statdict']['st_size']
       fpeek = fdata[0:Npdata]
       #                print('peek %d data B: "%s"' % (Npdata, fpeek))
       canDecodePeek = False
       for i in range(4):
           try:
               fps = fpeek[0:Npdata-i].decode('utf-8')
               canDecodePeek = True
           except:
               pass
           if canDecodePeek:
               break
       if canDecodePeek:
           fstr = fdata.decode('utf-8')
           fps = fps.lstrip()
           #                    print('peek %d data B: "%s"' % (Npdata, fps))
           if fps[0] == '<':
               #                        print('data is XML and decoded successfully')
               isXML = True
               if fps[0:5] == '<?xml':
                   enddecl = fstr.find('?>')
                   fstr = fstr[enddecl+2:]
    except BaseException as ex:
        print('Data fpeek "%s" (%d chars) failed: %s' % (path,len(fdata),ex))
    return (isXML, lsl, fdata, fstr)

def getp(request, path):
    errmsg = ''
    errors = []

    (isXML, lsl, fdata, fstr) = getxmlifposs(path)

    if isXML:
        ctype = "application/xml"
        (filename, file_extension) = os.path.splitext(path)
        if file_extension == ".xsl":
            ctype = "text/xml"
        return HttpResponse(fstr, content_type=ctype)
    else:
        if len(lsl) > 0 and len(lsl['info']) > 0 and lsl['info']['type'] == '-':
            mtype = mimetypes.guess_type(lsl['info']['name'])
            return HttpResponse(fdata, content_type=mtype[0])
            #                return HttpResponse(fdata, content_type="application/octet-stream")
        else:
#            print('The file is not a file:', path)
            errmsg = 'The file was not found'
            return HttpResponse(status=404)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **lsl }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ PathData(initial={'path': path}) ] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def getfileifposs(path, largeFileLimit=1e6):
    lsl = workdir.stat(path)
    if lsl is None or len(lsl) == 0 or len(lsl['info']) == 0 or lsl['info']['type'] != '-':
        return (False, lsl, '', '')

    print(f"get {lsl['info']['path']}")

    fsize = lsl['info']['statdict']['st_size']

    if fsize > largeFileLimit:
        fdata = workdir.getfile(path)
    else:
        fdata = workdir.getdoc(path)
    return (lsl, fdata)

def getdata(request, path):
    errmsg = ''
    errors = []

    (lsl, fdata) = getfileifposs(path)

    if len(lsl) > 0 and len(lsl['info']) > 0 and lsl['info']['type'] == '-':
        mtype = mimetypes.guess_type(lsl['info']['name'])
        fsize = lsl['info']['statdict']['st_size']
        fname = lsl['info']['name']
        if type(fdata) == type(b'') or type(fdata) == type(''):
            resp = HttpResponse(fdata)
        else:
            resp = StreamingHttpResponse(fdata)
        resp['Content-Length']     = f'{fsize}'
        resp['Content-Type']       = f'{mtype[0]}'
        resp['Content-Disposition']= f'attachment; filename="{fname}"'
        return resp
    else:
#        print('The file is not a file:', path)
        errmsg = 'The file was not found'
        return HttpResponse(status=404)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **lsl }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ PathData(initial={'path': path}) ] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def get(request):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = PathData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        path = cdata['path']

        return getp(request, path)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions
    }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

import time

def getrange(request, path, mode, start, end, transpose=False):

    lsl = {}

    errmsg = ''
    errors = []

    lsl = get_lsl(path)['lsl']
#    print('lsl', lsl)

    if len(lsl) > 0 and len(lsl['info']) > 0 and lsl['info']['type'] == '-':
        mtype = mimetypes.guess_type(lsl['info']['name'])
        t0 = time.time()
        if mode == 'head':
            fdata = workdir.head(path, end)
            start = -1
        elif mode == 'tail':
            (fdata, nmax) = workdir.tail(path, start)
            start = nmax - start
            end = nmax
        elif mode == 'range':
            fdata = workdir.range(path, start, end)
            t1 = time.time()
            print('Load %d-%d (%d lines): %g' % (start, end, end-start, t1-t0))
        elif mode == 'dlrange':
            fdata = workdir.head(path, 1)
            fdata += workdir.range(path, start, end)
            t1 = time.time()
            print('Load %d-%d (%d lines): %g' % (start, end, end-start, t1-t0))
        aenc = request.headers['Accept-Encoding']
#        fdata = gzip.compress(fdata.encode('utf8'), compresslevel=1)
#        t1 = time.time()
#        print('Compress %d-%d (%d lines): %g' % (start, end, end-start, t1-t0))

        # https://hacks.mozilla.org/2015/11/better-than-gzip-compression-with-brotli/
        if 'br' in aenc:
            fdata = brotli.compress(fdata.encode('utf8'), quality=1)
            t1 = time.time()
#            print('Compress %d-%d (%d lines): %g' % (start, end, end-start, t1-t0))
        resp = HttpResponse(fdata, content_type=mtype[0])
        #        resp['Content-Encoding'] = 'gzip'
        if 'br' in aenc:
            resp['Content-Encoding'] = 'br'
        dlfname = os.path.basename(path)
        filename, file_extension = os.path.splitext(dlfname)
        dlfname = '%s-range%d-%d%s' % (filename, start, end, file_extension)
        resp['Content-Disposition'] = 'attachment; filename="%s"' % (dlfname,)
        return resp
        #                return HttpResponse(fdata, content_type="application/octet-stream")
    else:
#        print('The file is not a file:', path)
        errmsg = 'The file was not found'

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **lsl }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ PathData(initial={'path': path}) ] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")



class HeadTailData(PathData):
    name = 'headtail'
    path = forms.CharField(required=False, max_length=1024, label='Mode')
    n = forms.IntegerField(label='Number', required=False)

class SecData(PathData):
    name = 'section'
    path = forms.CharField(required=False, max_length=1024, label='Mode')
    start = forms.IntegerField(label='Start', required=False)
    end = forms.IntegerField(label='End', required=False)


def get_head(request, path=None):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = HeadTailData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']
        n = cdata['n']
        if n is None:
            n = 1
        return getrange(request, path, 'head', None, n)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions
    }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def get_tail(request, path=None):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = HeadTailData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']
        n = cdata['n']
        if n is None:
            n = 10
        return getrange(request, path, 'tail', n, None)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'lsl': lsl,
        'errs': errors,
        'dir-actions': actions
    }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def get_range(request, path=None):

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = SecData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']
        start = cdata['start']
        end = cdata['end']

        return getrange(request, path, 'range', start, end)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = { 'errs': errors }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def get_dlrange(request, path=None):

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = SecData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        start = cdata['start']
        end = cdata['end']
        if path is None:
            path = cdata['path']

        return getrange(request, path, 'dlrange', start, end)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = { 'errs': errors }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def nlines(request, path=None):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = PathData(reqDict)
    n = 0

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        if path is None:
            path = cdata['path']

        n = workdir.nlines(path)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'n': n,
        'errs': errors
    }
    xcontext = {'xapp': 'main', 'view': 'path', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-atom.xml', context, content_type="application/xml")


class FindData(XCForm):
    title = 'Find'
    name = 'find'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'
    method = 'GET'

    path = forms.CharField(required=False, max_length=1024, label='Path')
    find = forms.CharField(required=False, max_length=1024, label='Match pattern')
    findpath = forms.BooleanField(required=False, label='Find paths')
    findsys = forms.BooleanField(required=False, label='Search system paths')
    igncase = forms.BooleanField(required=False, label='Ignore case')
    sort = forms.BooleanField(required=False, initial=True, label='Sort')

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def mkfindlist(findlist):
    findlist = [ {'path': os.path.dirname(f), 'name': os.path.basename(f)} for f in findlist ]
    return findlist


def find(request):
    context = {'xapp': 'main', 'view': 'find', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_find(request):

    lsl = {}

    errmsg = ''
    errors = []

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = FindData(reqDict)
    findlist = []
    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
#        print('find', cdata)
        path = cdata['path']
        find = cdata['find']
        findpath = cdata['findpath']
        findsys = cdata['findsys']
        igncase = cdata['igncase']
        sort = cdata['sort']

        if 'submit' in reqDict or len(find)>1 or findsys or findpath:
            if len(find) == 0:
                find = '*'
            if sort:
                findlist = mkfindlist(workdir.findsort(path, find, findpath, findsys, not igncase))
            else:
                findlist = mkfindlist(workdir.find(path, find, findpath, findsys, not igncase))

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    actions = fileactions
    try:
        if lsl['info']['type'] == 'd':
            actions = diractions
    except:
        pass

    data = {
        'lsl': lsl,
        'errs': errors,
        'findlist': findlist
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def ajax_findcmd(request):

    errmsg = ''
    errors = []
    cmd = ''

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST

    rdata = FindData(reqDict)
    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        print('findcmd', cdata)
        path = cdata['path']
        find = cdata['find']
        findpath = cdata['findpath']
        findsys = cdata['findsys']
        igncase = cdata['igncase']
        sort = cdata['sort']

        cmd = workdir.findcmd(path, find, findpath, findsys, not igncase)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors,
        'cmd': cmd
    }
    xcontext = {'xapp': 'main', 'view': 'textout', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def loadfonts():
    archive = zipfile.ZipFile('fontcache.zip', 'r')
    csvf = archive.read('fontcache.csv').decode('utf8')
    r = csv.reader(io.StringIO(csvf), delimiter=';')
    fontcache = [f for f in r]
    return fontcache

fontcache = loadfonts()

# 100   Thin (Hairline)
# 200   Extra Light (Ultra Light)
# 300   Light
# 400   Normal (Regular)
# 500   Medium
# 600   Semi Bold (Demi Bold)
# 700   Bold
# 800   Extra Bold (Ultra Bold)
# 900   Black (Heavy)
# 950   Extra Black (Ultra Black)

def findfont(which, weight, style, stretch):
    subfamily = ''
    if style == 'normal':
        style = 'regular'
    elif style == 'italic' or style == 'oblique':
        style = 'italic'
    candidates = [ f for f in fontcache if f[1].lower().find(which.lower()) > -1 ]
    [ print(c) for c in candidates ]
    if len(candidates) == 0:
        return None
    if stretch != 'normal':
        if stretch.find('cond'):
            stretch = 'condensed'
        print('select by strech')
        candidates = [ f for f in candidates if f[1].lower().find(stretch.lower()) > -1 ]
        [ print(c) for c in candidates ]
    candidates = [ f for f in candidates if f[2].lower().find(style.lower()) > -1 ]
    print('select by style:')
    [ print(c) for c in candidates ]
    if len(candidates) > 0:
        exact_candidates = [ f for f in candidates if f[1].lower() == which.lower() ]
        if len(exact_candidates) > 0:
            candidates = exact_candidates
    if len(candidates) == 0:
        return None
    return candidates[0][0]

#print(findfont('Open Sans', 'normal', 'normal', 'condensed'))

class GetfontData(GetfData):
    weight = forms.CharField(max_length=1024, label='Font Weight')
    style = forms.CharField(max_length=1024, label='Font Style')
    stretch = forms.CharField(max_length=1024, label='Font Stretch')

def getfont(request):
    context = {'xapp': 'main', 'view': 'getfont', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_getfont(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''
    findlist = []

    if request.method == "GET":
        reqDict = request.GET
        rdata = GetfontData(reqDict)
        res = rdata.is_valid()

    elif request.method == "POST":
        reqDict = request.POST
        rdata = GetfontData(reqDict)
        res = rdata.is_valid()

    cdata = rdata.cleaned_data

    if not res:
        errmsg = 'The form data is invalid'
    else:
        which = cdata['which']
        weight = cdata['weight']
        style = cdata['style']
        stretch = cdata['stretch']

        ffile = findfont(which, weight, style, stretch)

        if ffile is None:
            errmsg = 'File not found'
            rdata.add_error("which", 'File not found')
        else:
            # return HttpResponse(open(ffile, 'rb').read(), content_type=mimetypes.guess_type(ffile))
            # return redirect('/main/getf' + '/' + os.path.basename(ffile))
            return redirect('/main/get' + workdir.cutpath(ffile, workdir.base))

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")



class ActionData(XCForm):
    title = 'Action'
    name = 'action'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    path = forms.CharField(max_length=1024, label='Path')
    next_ = forms.CharField(required=False, max_length=1024, label='Follow-up action')
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)
    nowait = forms.ChoiceField(required=False, label='NoWait', choices=[('0',0),('1',1)])
    delay = forms.IntegerField(required=False, label='Delay')
    reply = forms.ChoiceField(required=False, label='Reply type', choices=[('xml','xml'),('html','html')])

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def action(request):
    if request.method == "POST":
        return ajax_action(request)
    context = {'xapp': 'main', 'view': 'action', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_action(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = ActionData(reqDict)
        res = rdata.is_valid()
        cdata = rdata.cleaned_data
        rdata = ActionData(initial=cdata)

    elif request.method == "POST":
        reqDict = request.POST
        rdata = ActionData(reqDict)

    if request.method == "POST":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            next_ = cdata['next_']
            delay = cdata['delay']

            print('action:', cdata['path'], cdata['next_'], cdata['nowait'], cdata['delay'])

            if len(next_) == 0:
                if reply == 'html':
                    next_ = reverse('main:action') + '?path=%s' % (path,)
                else:
                    next_ = reverse('main:ajax_action') + '?path=%s' % (path,)

            def replyRedirect():
                if delay is not None and delay > 0:
                    return render(request, 'common/delayed-redirect.html',
                                  {'next': next_, 'delay': delay, 'errmsg': errmsg})
                else:
                    return redirect(next_)

            lsl = workdir.stat(path)
#            print('lsl', lsl)
            if len(lsl['info']) == 0:
                errmsg = 'File not found'

            elif lsl['info']['exec'] == 0:
                errmsg = 'File is not executable'

            elif cdata['nowait'] == '1':
                result = workdir.execbg([workdir.realpath(path)],  {'user': request.user.username, 'comment': cdata['comment']})
                print('xc started process async:', result)
                return replyRedirect()
            else:
                result = workdir.execute([workdir.realpath(path)],  {'user': request.user.username, 'comment': cdata['comment']})
                if result.returncode != 0:
                    errmsg = 'Run command failed'
                print('xc started process sync:', result)
                return replyRedirect()

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})
        print('xc action error', errmsg)

    actions = fileactions

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'content': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


minCompressLen = 100
def sendPlainRespose(request, fdata, reply=None):
    if not reply:
        reply = 'plain'
    mtype = 'text/%s' % (reply,)
    renc = None
    if len(fdata) > minCompressLen:
        aenc = request.headers['Accept-Encoding']
        if 'br' in aenc:
            fdata = brotli.compress(fdata.encode('utf8'), quality=1)
            renc = 'br'
        elif 'gzip' in aenc:
            fdata = gzip.compress(fdata.encode('utf8'), compresslevel=1)
            renc = 'gzip'
    resp = HttpResponse(fdata, content_type=mtype)
    if renc:
        resp['Content-Encoding'] = renc
    return resp


def plain_status(request):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''
    path = ''

    if request.method == "GET":
        reqDict = request.GET
    elif request.method == "POST":
        reqDict = request.POST
    rdata = ActionData(reqDict)

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        path = cdata['path']
        reply = cdata['reply']

        lsl = workdir.stat(path)
        if len(lsl['info']) == 0:
            errmsg = 'File not found'

        elif lsl['info']['exec'] == 0:
            errmsg = 'File is not executable'

        else:
            result = workdir.pipe([workdir.realpath(path)])
            if result.returncode == 0:
                return sendPlainRespose(request, result.stdout, reply)
            else:
                errmsg = 'Run command failed'

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [rdata], 'xcontent': xcontent, 'xcontent_cdata': xmlesc(content) }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


psfields = dirman.getlines('psfields.txt')
psfields_def = ['user','pid','ppid','c','sz','rss','psr','stime','tty','time','cmd','lstart']
psfields_ws = ['args','cmd','comm','command','fname','ucmd','ucomm','lstart','bsdstart','start']

class PsData(XCForm):
    title = 'Process Info'
    name = 'ps'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    choices=[ (f.lower(), f) for f in psfields ]

    pid = forms.IntegerField(label='PID', required=False)
    proc = forms.CharField(label='CMD', required=False, max_length=100)
    fields = forms.MultipleChoiceField(label='Fields', required=False, choices=choices, widget=forms.SelectMultiple(choices))

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def ps(request):
    context = {'xapp': 'main', 'view': 'ps', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_ps(request, plain=False):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''

    if request.method == "GET":
        reqDict = request.GET

    elif request.method == "POST":
        reqDict = request.POST

    rdata = PsData(reqDict)
    if request.method == "POST" or  request.method == "GET":
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            pid = cdata['pid']
            proc = cdata['proc']
            fields = cdata['fields']

            if len(fields) == 0:
                fields = psfields_def

            if len(proc)>0:
                result = workdir.pipe(['ps', '-o', ' '.join(fields), '-ww', '-C', '%s' % (proc,)])
            elif pid is not None:
                result = workdir.pipe(['ps', '-o', ' '.join(fields), '-ww', '%d' % pid])
            else:
                result = workdir.pipe(['false'])
                pass
            if result.returncode == 0:
                content = result.stdout
            else:
                errmsg = 'Run command failed: %d' % (result.returncode,)

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    return sendPlainRespose(request, content)

def plain_ps(request):
    return ajax_ps(request, plain=True)


class CounterData(PathData):
    title = 'Counter'
    name = 'counter'
    method = 'POST'

    count = forms.IntegerField(label='Count', required=False)
    incr = forms.BooleanField(label='Increment', required=False)
    comment = forms.CharField(required=False, max_length=1024, label='Comment', widget=forms.Textarea)
    next_ = forms.CharField(required=False, max_length=1024, label='Next', widget=forms.Textarea, initial="counter")

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

def counter(request):
    context = {'xapp': 'main', 'view': 'counter', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

cre = re.compile(r'>[0-9]+<')

def ajax_counter(request, plain=False):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = CounterData(reqDict)
        res = rdata.is_valid()
        if res:
            path = rdata.cleaned_data['path']
            xcontent = getxmlifposs(path)[3]
        cdata = rdata.cleaned_data
        rdata = CounterData(initial=cdata)

    elif request.method == "POST":
        reqDict = request.POST
        rdata = CounterData(reqDict)

    if request.method == "POST":
        def mkcounter(val):
            return ('<counter xmlns="http://ai-and-it.de/xmlns/2020/xc">%d</counter>' % (val,)).encode('ascii')
        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            path = cdata['path']
            incr = cdata['incr']
            count = cdata['count']
            next_ = cdata['next_']

#            print('Counter:', path)
            if incr:
                lock = workdir.getlock(path)
                if lock is None:
                    errmsg = 'Lock could not be obtained'
                else:
                    r = getxmlifposs(path)
                    if r[0]:
                        r = r[3]
    #                    print('Count XML:', r)
                        counts = cre.findall(r)
                        if len(counts) > 0:
    #                        print('Count String:', counts)
                            count = int(counts[0][1:-1])
    #                        print('Count Value:', count)
                            workdir.replacedoc(path, mkcounter(count+1),
                                               {'user': request.user.username, 'comment': 'counter incr:' + cdata['comment']})
                            workdir.rellock(lock)
                            return redirect(reverse('main:ajax_%s' % (next_,)) + '?path=%s' % (path,))
                        else:
                            errmsg = 'The counter is invalid'
                    else:
                        errmsg = 'The counter is invalid'
                    workdir.rellock(lock)
            elif count is not None:
                lock = workdir.getlock(path)
                if lock is None:
                    errmsg = 'Lock could not be obtained'
                else:
                    workdir.replacedoc(path, mkcounter(count),
                                       {'user': request.user.username, 'comment': 'counter set:' + cdata['comment']})
                    workdir.rellock(lock)
            else:
                pass

            xcontent = getxmlifposs(path)[3]

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'xcontent_cdata': xmlesc(content) }
    return render(request, 'common/xc-msg.xml' if not plain else 'common/xc-atom.xml',
                  context, content_type="application/xml")

def plain_counter(request):
    return ajax_counter(request, plain=True)


def cid(request):
    context = {'xapp': 'main', 'view': 'cid', 'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': [], 'number': 0}
    return render(request, 'common/wframe.html', context)

cre = re.compile(r'>[0-9]+<')

def ajax_cid(request, plain=False):

    lsl = ''

    errmsg = ''
    errors = []
    xcontent = ''
    content = ''

    if request.method == "GET":
        reqDict = request.GET
        rdata = PathData(reqDict)
    elif request.method == "POST":
        reqDict = request.POST
        rdata = PathData(reqDict)

    def mkcounter(val):
        return ('<counter xmlns="http://ai-and-it.de/xmlns/2020/xcerp">%d</counter>' % (val,)).encode('ascii')

    res = rdata.is_valid()
    if not res:
        errmsg = 'The form data is invalid'
    else:
        cdata = rdata.cleaned_data
        path = cdata['path']

        lock = workdir.getlock(path)
        if lock is None:
            errmsg = 'Lock could not be obtained'
        else:
            r = getxmlifposs(path)
            if r[0]:
                r = r[3]
    #                    print('Count XML:', r)
                counts = cre.findall(r)
                if len(counts) > 0:
    #                        print('Count String:', counts)
                    count = int(counts[0][1:-1])
    #                        print('Count Value:', count)
                    workdir.replacedoc(path, mkcounter(count+1),
                                       {'user': request.user.username, 'comment': 'counter cid'})
                    workdir.rellock(lock)
                    return redirect(reverse('main:%s_counter' % ('plain' if plain else 'ajax',)) + '?path=%s' % (path,))
                else:
                    errmsg = 'The counter is invalid'
            else:
                errmsg = 'The counter is invalid'
            workdir.rellock(lock)

            xcontent = getxmlifposs(path)[3]

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    data = { **data, **get_lsl(path) }
    xcontext = {'xapp': 'main', 'view': 'dirmanform', 'cgi': getAllCGI(reqDict), 'data': data, 'user': userdict(request.user)}
    dx = dictxml(xcontext)
    context = { 'context_xml': dx, 'forms': [ rdata], 'xcontent': xcontent, 'xcontent_cdata': xmlesc(content) }
    return render(request, 'common/xcerp-msg.xml' if not plain else 'common/xcerp-atom.xml',
                  context, content_type="application/xml")

def plain_cid(request):
    return ajax_cid(request, plain=True)
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")
