"""
Django settings for xc project.

Generated by 'django-admin startproject' using Django 2.2.12.

For more information on this file, see
https://docs.djangoproject.com/en/2.2/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/2.2/ref/settings/
"""

import os, sys

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/2.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = '324asdxcjkadasdaasdhf%as08423nkfdnasshdd*coql4^o*8=@kr2k@gp'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = [
    'raspberrypi',
    'example.local',
    'localhost'
]

LOGIN_URL = 'login:login'

# Application definition

INSTALLED_APPS = [
    'login.apps.LoginConfig',
    'register.apps.RegisterConfig',
    'main.apps.MainConfig',
    'msgs.apps.MsgsConfig',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'xc.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'xc.wsgi.application'


# Database
# https://docs.djangoproject.com/en/2.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}


# Password validation
# https://docs.djangoproject.com/en/2.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/2.2/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/2.2/howto/static-files/

#STATIC_ROOT = os.path.join(BASE_DIR, "static/")
# es gibt nur ein static, login/static

STATIC_URL = '/static/'

MAIN_FRAME = 'xframe.html'

DEFAULT_FROM_EMAIL = 'info@example.com'

EMAIL_HOST = 'smtp.example.com'
EMAIL_HOST_USER = 'emailuser'
EMAIL_HOST_PASSWORD = 'emailsecret'
EMAIL_USE_TLS = True
EMAIL_USE_SSL = False

xc_appdir = '/var/lib/xc/xc-application'
try:
    os.lstat(xc_appdir)
except:
    xc_appdir = os.path.join(os.path.abspath(os.path.join(BASE_DIR, '..')), 'data')
XC_WORKDIR = xc_appdir

XC_HOME_PATH = 'config.xml'

XC_USE_GIT=False

DATA_UPLOAD_MAX_NUMBER_FIELDS = 200

userPyPath = XC_WORKDIR + '/files/py'
if os.path.exists(userPyPath):
    sys.path.append(userPyPath)

sysPyPath = '/etc/xc/py'
if os.path.exists(sysPyPath):
    sys.path.append(sysPyPath)

try:
    from local_settings import *
except ImportError as e:
    print(e)
    pass

try:
    from system_settings import *
except ImportError as e:
    print(e)
    pass

try:
    XC_TRACE = DEBUG
except:
    XC_TRACE = False


XC_INVITE = True
XC_REGISTER = False

siteDomain = 'www.example.com'
siteName = 'XC'
