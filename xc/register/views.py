from django.shortcuts import render, redirect

from django.http import HttpResponse

from django.contrib.auth import authenticate, login
from django.contrib.auth.models import User

from django.urls import reverse

from xc.tools import *

from django import forms

from register.models import ActivationCode, UserIP, unsign_acode

import uuid

from xc import settings

class RegistrationData(XCForm):
    title = 'Registration'
    name = 'register'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    username = forms.CharField(max_length=100)
    email = forms.EmailField(initial='', label='Email address')
#    email = forms.CharField(max_length=100)
    firstname = forms.CharField(max_length=100, required=False, label='First name')
    lastname = forms.CharField(max_length=100, required=False, label='Last name')
    password = forms.CharField(max_length=100, label='Choose password', widget=forms.PasswordInput)
    password2 = forms.CharField(max_length=100, label='Confirm password', widget=forms.PasswordInput)
    confirmtos = forms.BooleanField(required=False, label='Confirm TOS and PP')

    def clean(self):
        cleaned_data = super().clean()
        pass1 = cleaned_data.get("password")
        pass2 = cleaned_data.get("password2")
        if pass1 != pass2:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Passwords are not the same'})
            self.add_error('password', msg)
            self.add_error('password2', msg)
        if len(pass1) < 6:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Password is too short (6 chars min)'})
            self.add_error('password', msg)
        tos = cleaned_data.get("confirmtos")
        if not tos:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Please accept our TOS.'})
            self.add_error('confirmtos', msg)
        return cleaned_data


class ActivationData(XCForm):
    title = 'Activation'
    name = 'activate'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    code = forms.CharField(max_length=100)

    def clean(self):
        print('form.clean')
        cleaned_data = super().clean()
        return cleaned_data

class CreateUserData(RegistrationData):
    title = 'CreateUser'
    name = 'createuser'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    code = forms.CharField(widget=forms.HiddenInput)
    email = forms.CharField(widget=forms.HiddenInput, required=False)

    def clean(self):
        cleaned_data = super().clean()

        rcode = cleaned_data.get("code")
        email = cleaned_data["email"]

        try:
            code = unsign_acode(rcode)
            actcode = ActivationCode.objects.filter(code=code).first()
        except BaseException as ce:
            errmsg = 'Activation code is invalid'
            self.add_error('code', errmsg)
            actcode = None

        if actcode is None or len(actcode.email) == 0 or len(email) > 0:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Registration code not found'})
            self.add_error('code', msg)

        return cleaned_data


class ResendActivationData(XCForm):
    title = 'Resend activation'
    name = 'resend_activation'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    email = forms.EmailField(max_length=100)

    def clean(self):
        print('form.clean')
        cleaned_data = super().clean()

        email = cleaned_data.get("email")

        actcode = ActivationCode.objects.filter(user__email=email).first()
        if actcode is None:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'No registration code for this email address found'})
            self.add_error('email', msg)

        elif actcode.user.is_active:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'User is active already'})
            self.add_error('email', msg)

        return cleaned_data


def index(request):
    context = {'xapp': 'register', 'view': 'index', 'cgi': request.GET,
               'data': [], 'number': 0}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_index(request):
    print(list(request.GET.items()))
    xcontext = {'xapp': 'register', 'view': 'register',
               'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': []}
    dx = dictxml(xcontext)
    print(xcontext)
    print(dx)
    context = { 'context_xml': dx, 'forms': [RegistrationData()] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def register(request):
    context = {'xapp': 'register', 'view': 'index', 'cgi': getAllCGI(request.POST),
               'data': []}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_register(request):

    errmsg = ''
    errors = []
    res = False

    if request.method == "GET":
        rdata = RegistrationData()
    elif request.method == "POST":
        rdata = RegistrationData(request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            username = cdata['username']
            email = cdata['email']
            fname = cdata['firstname']
            lname = cdata['lastname']
            if not settings.XC_REGISTER:
                errmsg = 'User invitations are disabled'
            elif User.objects.filter(username=username).first() is not None:
                errmsg = 'User exists'
                rdata.add_error('username', errmsg)
            elif User.objects.filter(email=email).first() is not None:
                errmsg = 'Email exists'
                rdata.add_error('email', errmsg)
            else:
                actcode = uuid.uuid4()
                newuser = User.objects.create_user(username, email, cdata['password'], is_active=False)
                actcode = ActivationCode.objects.create(code=actcode, user=newuser, creator=newuser, userip=get_ip(ip=request.META['REMOTE_ADDR']))
                if newuser is None:
                    errmsg = 'Failed to create User'
                elif actcode is None:
                    errmsg = 'Failed to create activation code'
                else:
                    sendActivationEmail(newuser.email, actcode.sign())
                    return redirect('register:ajax_activate')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'valid': res,
        'errs': errors
    }
    xcontext = {'xapp': 'register', 'view': 'register',
                'cgi': getAllCGI(request.POST),
                'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def activate(request):
    context = {'xapp': 'register', 'view': 'activate',
               'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': []}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_activate(request):
    errmsg = ''
    errors = []

    if request.method == "GET":
        rdata = ActivationData(initial=request.GET)
    elif request.method == "POST":
        rdata = ActivationData(request.POST)

        res = rdata.is_valid()

        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            code = rcode = cdata['code']

            # d10fbef5-5cdd-4fd6-9121-802cdc62daae

            try:
                code = unsign_acode(rcode)
                actcode = ActivationCode.objects.filter(code=code).first()
            except BaseException as ce:
                print(ce)
                errmsg = 'Activation code is invalid'
                rdata.add_error('code', errmsg)
                actcode = None

            if actcode is None:
                errmsg = 'Activation code not found'
            else:
                user = actcode.user
                if actcode.mode == 'acc.act':
                    if user.is_active:
                        errmsg = 'Activated already'
                    else:
                        user.is_active = True
                        user.save()
                        actcode.delete()
                        return redirect('login:ajax_index')
                elif actcode.mode == 'acc.login':
                    if not user.is_active:
                        errmsg = 'User account deactivated'
                    else:
                        login(request, user)
                        actcode.delete()
                        return redirect('login:ajax_reset_password')
                elif actcode.mode == 'acc.invite':
                    actcode.mode = 'acc.createUser'
                    actcode.save()
                    return redirect(reverse('register:ajax_createuser') + '?code=' + actcode.sign())
                elif actcode.mode == 'acc.createUser':
                    return redirect(reverse('register:ajax_createuser') + '?code=' + actcode.sign())

    else:
        errmsg = 'Invalid request method'

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'register', 'view': 'activate', 'cgi': getAllCGI(request.POST), 'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def resend_activation(request):
    context = {'xapp': 'register', 'view': 'resend_activation',
               'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': []}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_resend_activation(request):

    errmsg = ''
    errors = []

    if request.method == "GET":
        rdata = ResendActivationData()
    elif request.method == "POST":
        rdata = ResendActivationData(request.POST)

        res = rdata.is_valid()

        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            email = cdata['email']

            actcode = ActivationCode.objects.filter(user__email=email).first()

            if actcode is None:
                errmsg = 'Activation code not found'
            else:
                user = actcode.user
                if user.is_active is None:
                    errmsg = 'Activated already'
                else:
                    email = user.email
                    sendActivationEmail(user.email, actcode.sign())
                    return redirect('register:ajax_activate')

    else:
        errmsg = 'Invalid request method'

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'register', 'view': 'resend_activation', 'cgi': getAllCGI(request.POST), 'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def createuser(request):
    context = {'xapp': 'register', 'view': 'createuser',
               'cgij': xmlesc(json.dumps(getAllCGI(request.GET))), 'data': []}
    return render(request, 'common/' + settings.MAIN_FRAME, context)

def ajax_createuser(request):

    errmsg = ''
    errors = []
    res = False

    if request.method == "GET":
        rdata = CreateUserData(initial=request.GET)
    elif request.method == "POST":
        rdata = CreateUserData(request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data

            actcode = ActivationCode.objects.filter(code=unsign_acode(cdata['code'])).first()

            username = cdata['username']
            email = actcode.email
            fname = cdata['firstname']
            lname = cdata['lastname']
            if not settings.XC_INVITE:
                errmsg = 'User invitations are disabled'
            elif User.objects.filter(username=username).first() is not None:
                errmsg = 'User exists'
                rdata.add_error('username', errmsg)
            elif User.objects.filter(email=email).first() is not None:
                errmsg = 'User email exists'
                rdata.add_error('username', errmsg)
            else:
                newuser = User.objects.create_user(username, email, cdata['password'], is_active=True)
                newuser.first_name = fname
                newuser.last_name = lname
                newuser.save()
                actcode.user = newuser
                actcode.mode = 'noacc.created'
                actcode.save()
                return redirect('login:ajax_index')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'valid': res,
        'errs': errors
    }
    xcontext = {'xapp': 'register', 'view': 'createuser',
                'cgi': getAllCGI(request.POST),
                'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")
