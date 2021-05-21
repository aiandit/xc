from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('index', views.index, name='index'),
    path('login/', views.index, name='login'),
    path('login', views.index, name='login'),
    path('logout', views.logout_view, name='logout'),

    path('ajax_index', views.ajax_index, name='ajax_index'),
    path('ajax_login', views.ajax_login_view, name='ajax_login'),
    path('ajax_logout', views.ajax_logout_view, name='ajax_logout'),

    path('profile', views.profile, name='profile'),
    path('edit_profile', views.edit_profile, name='edit_profile'),
    path('set_password', views.set_password, name='set_password'),
    path('reset_password', views.reset_password, name='reset_password'),
    path('deleteprofile', views.deleteprofile, name='deleteprofile'),
    path('resendpassword', views.resendpassword, name='resendpassword'),
    path('invite', views.sendinvite_view, name='invite'),
    path('deleteinvite', views.deleteinvite_view, name='deleteinvite'),
#    path('user', views.user, name='user'),
#    path('delete_profile', views.delete_profile, name='delete_profile'),

    path('ajax_profile', views.ajax_profile, name='ajax_profile'),
    path('ajax_edit_profile', views.ajax_edit_profile, name='ajax_edit_profile'),
    path('ajax_set_password', views.ajax_set_password, name='ajax_set_password'),
    path('ajax_reset_password', views.ajax_reset_password, name='ajax_reset_password'),
    path('ajax_deleteprofile', views.ajax_deleteprofile, name='ajax_deleteprofile'),
    path('ajax_resendpassword', views.ajax_resendpassword, name='ajax_resendpassword'),
    path('ajax_invite', views.ajax_sendinvite_view, name='ajax_invite'),
    path('ajax_deleteinvite', views.ajax_deleteinvite_view, name='ajax_deleteinvite'),
#    path('ajax_user', views.ajax_user, name='ajax_user'),
#    path('ajax_delete_profile', views.ajax_delete_profile, name='ajax_delete_profile'),

]

app_name = 'login'
