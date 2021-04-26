import uuid

from django.shortcuts import render, redirect

from django.http import HttpResponse

from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User

from django.contrib.auth.decorators import login_required

from django.shortcuts import render

from register.models import ActivationCode, UserIP, unsign_acode

from xc.tools import *

from xc import settings

def index(request):
    context = {'xapp': 'login', 'view': 'index', 'cgi': request.GET,
               'data': [], 'number': 0}
    return render(request, 'common/xframe.html', context)

def ajax_index(request):
    print(list(request.GET.items()))
    xcontext = {'xapp': 'login', 'view': 'login', 'cgi': getAllCGI(request.GET), 'data': []}
    dx = dictxml(xcontext)
    print(xcontext)
    print(dx)
    context = { 'context_xml': dx, 'forms': [LoginData()] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


def login_view(request):
    context = {'xapp': 'login', 'view': 'login', 'cgi': getAllCGI(request.POST),
               'data': []}
    return render(request, 'common/xframe.html', context)

class LoginData(XCForm):
    name = 'login'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    username = forms.CharField(max_length=100, label='User name')
    password = forms.CharField(max_length=100, label='Password', widget=forms.PasswordInput)

    def clean(self):
        cleaned_data = super().clean()

        user = cleaned_data.get("username")
        passw = cleaned_data.get("password")

        user = authenticate(username=user, password=passw)
        if user is None:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Login failed'})
            self.add_error('username', msg)
            self.add_error('password', msg)

        return cleaned_data


def ajax_login_view(request):

    errmsg = ''
    errors = []

    if request.method == "GET":
        rdata = LoginData()
    elif request.method == "POST":
        rdata = LoginData(request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            user = cdata['username']
            passw = cdata['password']

            user = authenticate(username=user, password=passw)

            if user is None:
                errmsg = 'Not authenticated'
            else:
                login(request, user)
#                return redirect('login:ajax_profile')
                return redirect('main:ajax_home')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    print('ajax_login_view:', rdata)
    xcontext = {'xapp': 'login', 'view': 'login', 'cgi': getAllCGI(request.POST), 'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class LogoutData(XCForm):
    name = 'logout'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

@login_required
def logout_view(request):
    context = {'xapp': 'login', 'view': 'logout', 'cgi': getAllCGI(request.POST),
               'data': []}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_logout_view(request):

    errmsg = ''
    errors = []

    user = request.user

    if request.method == "GET":
        rdata = LogoutData()
    elif request.method == "POST":
        rdata = LogoutData(request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            logout(request)
            return redirect('main:ajax_home')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    print('ajax_logout_view:', rdata)
    xcontext = {'xapp': 'login', 'view': 'logout', 'cgi': getAllCGI(request.POST), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class DeleteprofileData(XCForm):
    title = 'Delete Profile'
    name = 'deleteprofile'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    confirm = forms.BooleanField()

    def clean(self):
        cleaned_data = super().clean()
        return cleaned_data

@login_required
def deleteprofile(request):
    context = {'xapp': 'login', 'view': 'deleteprofile', 'cgi': getAllCGI(request.POST),
               'data': []}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_deleteprofile(request):

    errmsg = ''
    errors = []

    user = request.user

    if request.method == "GET":
        rdata = DeleteprofileData()
    elif request.method == "POST":
        rdata = DeleteprofileData(request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:

            conf = rdata.cleaned_data['confirm']

            if not conf:
                errmsg = 'Not confirmed'
                rdata.add_error(confirm, errmsg)
            else:
                user.delete()
                return redirect('login:ajax_login')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    print('ajax_deleteprofile_view:', rdata)
    xcontext = {'xapp': 'login', 'view': 'deleteprofile', 'cgi': getAllCGI(request.POST), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class EditProfileData(XCForm):
    name = 'edit_profile'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    firstname = forms.CharField(max_length=100, required=False, label='First name')
    lastname = forms.CharField(max_length=100, required=False, label='Last name')

    def clean(self):
        cleaned_data = super().clean()
        fname = cleaned_data.get("firstname")
        lname = cleaned_data.get("lastname")
        if len(fname) != 0 and len(lname) == 0 or len(lname) != 0 and len(fname) == 0:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Set both or none of first and last name'})
            self.add_error('firstname', msg)
            self.add_error('lastname', msg)
        return cleaned_data


@login_required
def profile(request):
    user = request.user
    context = {'xapp': 'login', 'view': 'profile', 'cgi': getAllCGI(request.POST), 'data': [], 'user': user}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_profile(request):

    errmsg = ''
    errors = []

    user = request.user

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'login', 'view': 'profile', 'cgi': getAllCGI(request.GET), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

@login_required
def edit_profile(request):
    user = request.user
    context = {'xapp': 'login', 'view': 'edit_profile', 'cgi': getAllCGI(request.POST), 'data': [], 'user': user}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_edit_profile(request):

    errmsg = ''
    errors = []

    user = request.user

    initial={'firstname': user.first_name, 'lastname': user.last_name}

    if request.method == "GET":
        rdata = EditProfileData(initial=initial)
    elif request.method == "POST":
        rdata = EditProfileData(request.POST, initial=initial)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data

            submitEnd = True

            user.first_name = cdata['firstname']
            user.last_name = cdata['lastname']

            if submitEnd:
                if rdata.has_changed():
                    user.save()
                    return redirect('login:ajax_profile')
                else:
                    errmsg = 'No changes'
            else:
                user.save()
                return redirect('login:ajax_edit_profile')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'login', 'view': 'edit_profile', 'cgi': getAllCGI(request.POST), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class SetPasswordData(XCForm):
    def __init__(self, request, *args, **kwargs):
        self.request = request
        super(SetPasswordData, self).__init__(*args, **kwargs)

    name = 'set_password'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    password = forms.CharField(max_length=100, label='Current password', widget=forms.PasswordInput)
    npassword1 = forms.CharField(max_length=100, label='Choose password', widget=forms.PasswordInput)
    npassword2 = forms.CharField(max_length=100, label='Confirm Password', widget=forms.PasswordInput)

    def clean(self):
        print('form.clean')
        cleaned_data = super().clean()
        cpass = cleaned_data.get("password")
        pass1 = cleaned_data.get("npassword1")
        pass2 = cleaned_data.get("npassword2")
        if pass1 != pass2:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Passwords do not coincide'})
            self.add_error('npassword1', msg)
            self.add_error('npassword2', msg)
        if len(pass1) < 6 \
           and not self.request.user.is_superuser:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Password is too short (6 chars min)'})
            self.add_error('password', msg)
        return cleaned_data



@login_required
def set_password(request):
    user = request.user
    context = {'xapp': 'login', 'view': 'set_password', 'cgi': getAllCGI(request.POST), 'data': [], 'user': user}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_set_password(request):

    errmsg = ''
    errors = []

    user = request.user

    if request.method == "GET":
        rdata = SetPasswordData(request)
    elif request.method == "POST":
        rdata = SetPasswordData(request, request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data

            cpass = cdata.get("password")
            npass = cdata.get("npassword1")

            cuser = authenticate(username=request.user.username, password=cpass)

            if cuser is None:
                errmsg = 'Current password mismatch'
                rdata.add_error('password', errmsg)
            else:
                user.set_password(npass)
                user.save()
                return redirect('login:ajax_login')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'login', 'view': 'set_password', 'cgi': getAllCGI(request.POST), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class ResetPasswordData(XCForm):
    def __init__(self, request, *args, **kwargs):
        self.request = request
        super(ResetPasswordData, self).__init__(*args, **kwargs)

    name = 'reset_password'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    npassword1 = forms.CharField(max_length=100, label='Choose password', widget=forms.PasswordInput)
    npassword2 = forms.CharField(max_length=100, label='Confirm Password', widget=forms.PasswordInput)

    def clean(self):
        print('form.clean')
        cleaned_data = super().clean()
        pass1 = cleaned_data.get("npassword1")
        pass2 = cleaned_data.get("npassword2")
        if pass1 != pass2:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Passwords do not coincide'})
            self.add_error('npassword1', msg)
            self.add_error('npassword2', msg)
        if len(pass1) < 6:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'Password is too short (6 chars min)'})
            self.add_error('password', msg)
        return cleaned_data


@login_required
def reset_password(request):
    user = request.user
    context = {'xapp': 'login', 'view': 'reset_password', 'cgi': getAllCGI(request.POST), 'data': [], 'user': user}
    return render(request, 'common/xframe.html', context)

@login_required
def ajax_reset_password(request):

    errmsg = ''
    errors = []

    user = request.user

    if request.method == "GET":
        rdata = ResetPasswordData(request)
    elif request.method == "POST":
        rdata = ResetPasswordData(request, request.POST)

        res = rdata.is_valid()
        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data

            cpass = cdata.get("password")
            npass = cdata.get("npassword1")

            user.set_password(npass)
            user.save()
            return redirect('login:ajax_login')

    if len(errmsg):
        errors = [ {'errmsg': errmsg, 'type': 'fatal'} ]

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'login', 'view': 'reset_password', 'cgi': getAllCGI(request.POST), 'data': data, 'user': userdict(user)}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")


class ResendpasswordData(XCForm):
    name = 'resendpassword'
    auto_id='id_for_%s'
    error_css_class = 'error'
    required_css_class = 'required'

    email = forms.EmailField(max_length=100)

    def clean(self):
        print('form.clean')
        cleaned_data = super().clean()

        email = cleaned_data.get("email")

        user = User.objects.filter(email=email).first()
        if user is None:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'No user for this email address found'})
            self.add_error('email', msg)

        elif not user.is_active:
            msg = forms.ValidationError('%(value)s',
                                        code='invalid',
                                        params={'value': 'User account is not active'})
            self.add_error('email', msg)

        return cleaned_data


def resendpassword(request):
    context = {'xapp': 'login', 'view': 'resendpassword', 'cgi': getAllCGI(request.POST),
               'data': []}
    return render(request, 'common/xframe.html', context)

def ajax_resendpassword(request):

    errmsg = ''
    errors = []

    if request.method == "GET":
        rdata = ResendpasswordData()
    elif request.method == "POST":
        rdata = ResendpasswordData(request.POST)

        res = rdata.is_valid()

        if not res:
            errmsg = 'The form data is invalid'
        else:
            cdata = rdata.cleaned_data
            email = cdata['email']

            user = User.objects.filter(email=email).first()

            if user is None:
                errmsg = 'No such email found'
            else:
                if not user.is_active:
                    errmsg = 'User is not activate'
                else:
                    email = user.email
                    actcode = ActivationCode.objects.create(code=uuid.uuid4(), user=user, userip=get_ip(request), mode='acc.login')
                    sendActivationEmail(actcode.user.email, actcode.sign())
                    return redirect('register:ajax_activate')

    else:
        errmsg = 'Invalid request method'

    if len(errmsg):
        errors.append({'errmsg': errmsg, 'type': 'fatal'})

    data = {
        'errs': errors
    }
    xcontext = {'xapp': 'login', 'view': 'resendpassword', 'cgi': getAllCGI(request.POST), 'data': data}
    context = { 'context_xml': dictxml(xcontext), 'forms': [rdata] }
    return render(request, 'common/xc-msg.xml', context, content_type="application/xml")

def favicon(request):
    return redirect('/main/getf/' + 'favicon.ico')
#    return redirect(settings.STATIC_URL + 'favicon.ico')
