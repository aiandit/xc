from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('index', views.index, name='index'),
    path('register', views.index, name='register'),
    path('activate', views.activate, name='activate'),
    path('createuser', views.createuser, name='createuser'),
    path('resend_activation', views.resend_activation, name='resend_activation'),

    path('ajax_index', views.ajax_index, name='ajax_index'),
    path('ajax_register', views.ajax_register, name='ajax_register'),
    path('ajax_activate', views.ajax_activate, name='ajax_activate'),
    path('ajax_createuser', views.ajax_createuser, name='ajax_createuser'),
    path('ajax_resend_activation', views.ajax_resend_activation, name='ajax_resend_activation'),
]

app_name = 'register'
