from django.urls import path

from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('home/', views.home, name='home'),
    path('ajax_home/', views.ajax_home, name='ajax_home'),

    path('index/', views.index, name='index'),
    path('path/', views.path, name='path'),
    path('newdoc', views.newdoc, name='newdoc'),
    path('newdir', views.newdir, name='newdir'),
    path('delete', views.delete, name='delete'),
    path('view/', views.view_view, name='view'),
    path('view/<path:path>', views.view_view, name='view'),
    path('edit', views.edit, name='edit'),
    path('append', views.append, name='append'),
    path('which', views.which, name='which'),
    path('runwhich', views.runwhich, name='runwhich'),
    path('clone', views.clone, name='clone'),
    path('transform', views.transform, name='transform'),
    path('move', views.move, name='move'),
    path('fileupload', views.fileupload, name='fileupload'),
    path('replace', views.replace, name='replace'),
    path('find', views.find, name='find'),

    path('action', views.action, name='action'),
    path('ajax_action', views.ajax_action, name='ajax_action'),

#    path('status', views.status, name='status'),
#    path('ajax_status', views.ajax_status, name='ajax_status'),
    path('plain_status', views.plain_status, name='plain_status'),

    path('ps', views.ps, name='ps'),
    path('ajax_ps', views.ajax_ps, name='ajax_ps'),
    path('plain_ps', views.plain_ps, name='plain_ps'),

    path('counter', views.counter, name='counter'),
    path('ajax_counter', views.ajax_counter, name='ajax_counter'),
    path('plain_counter', views.plain_counter, name='plain_counter'),

    path('id', views.cid, name='cid'),
    path('ajax_id', views.ajax_cid, name='ajax_cid'),
    path('plain_id', views.plain_cid, name='plain_cid'),

    path('get/', views.get, name='get'),
    path('get/<path:path>', views.getp, name='getp'),
    path('ajax_get/', views.get, name='ajax_get'),

    path('nlines/', views.nlines, name='nlines'),
    path('nlines/<path:path>', views.nlines, name='nlines'),

    path('head/', views.get_head, name='head'),
    path('head/<path:path>', views.get_head, name='head'),

    path('tail/', views.get_tail, name='tail'),
    path('tail/<path:path>', views.get_tail, name='tail'),

    path('range/', views.get_range, name='range'),
    path('range/<path:path>', views.get_range, name='range'),

    path('dlrange/<path:path>', views.get_dlrange, name='dlrange'),
    path('dlrange/', views.get_dlrange, name='dlrange'),

    path('getf/', views.getf, name='getf'),
    path('getf/<path:pattern>', views.getfp, name='getfp'),
    path('ajax_getf/', views.getf, name='ajax_getf'),

    path('download/<path:path>', views.getdata, name='getdata'),

    path('getfont', views.ajax_getfont, name='getfont'),

    path('ajax_index', views.ajax_index, name='ajax_index'),
    path('ajax_path', views.ajax_path, name='ajax_path'),
    path('ajax_newdoc', views.ajax_newdoc, name='ajax_newdoc'),
    path('ajax_newdir', views.ajax_newdir, name='ajax_newdir'),
    path('ajax_delete', views.ajax_delete, name='ajax_delete'),
    path('ajax_view/', views.ajax_view, name='ajax_view'),
    path('ajax_view/<path:path>', views.ajax_view, name='ajax_view'),
    path('ajax_edit', views.ajax_edit, name='ajax_edit'),
    path('ajax_append', views.ajax_append, name='ajax_append'),
    path('ajax_which', views.ajax_which, name='ajax_which'),
    path('ajax_runwhich', views.ajax_runwhich, name='ajax_runwhich'),
    path('ajax_clone', views.ajax_clone, name='ajax_clone'),
    path('ajax_transform', views.ajax_transform, name='ajax_transform'),
    path('ajax_move', views.ajax_move, name='ajax_move'),
    path('ajax_fileupload', views.ajax_fileupload, name='ajax_fileupload'),
    path('ajax_replace', views.ajax_replace, name='ajax_replace'),
    path('ajax_find', views.ajax_find, name='ajax_find')

]

app_name = 'main'
