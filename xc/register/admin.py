from django.contrib import admin

# Register your models here.


from django.contrib import admin

from .models import ActivationCode, UserIP


class ActivationCodeAdmin(admin.ModelAdmin):
    search_fields = ['code', 'user__username', 'userip__ip', 'email']
    list_display = ('code', 'user', 'creator', 'mode', 'userip', 'pub_date', 'mod_date')
    fields = ['mode', 'user', 'creator', 'email', 'userip', 'pub_date', 'mod_date']

admin.site.register(ActivationCode, ActivationCodeAdmin)


class UserIPAdmin(admin.ModelAdmin):
    list_display = ('ip',)
    fields = ['ip']

admin.site.register(UserIP, UserIPAdmin)
