from django.urls import path

from . import views

urlpatterns = [
    path('', views.send, name='index'),
    path('index', views.send, name='index'),
    path('send', views.send, name='send'),

    path('ajax_send', views.ajax_send, name='ajax_send'),

    path('chat/<str:to>/', views.psend, name='psend'),
    path('ajax_chat/<str:to>/', views.ajax_psend, name='ajax_psend'),
]

app_name = 'msgs'
