from django.db import models

from django.core.signing import Signer, TimestampSigner

from django.contrib.auth.models import User

from django.utils import timezone

import uuid

class UserIP(models.Model):
#    ip = models.IPAddressField(primary_key=True)
    ip = models.GenericIPAddressField(protocol='both', unpack_ipv4=True, unique=True)
    def __unicode__(self):
        return "%s" % self.ip

salt='acctcode9d898'

class ActivationCode(models.Model):
    code = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='creator', null=True)
    email = models.TextField(max_length=100, default='')
    userip = models.ForeignKey(UserIP, on_delete=models.CASCADE)
    mode = models.TextField(max_length=10, default='acc.act')
    pub_date = models.DateTimeField('date created', default=timezone.now)
    mod_date = models.DateTimeField('date changed', default=timezone.now)
    def asxml(self):
        return "<acode><id>%s</id><user>%s</user><creator>%s</creator><email>%s</email><date>%s</date><mode>%s</mode></acode>" % \
            (self.code, self.user, self.creator, self.email, self.mod_date.timestamp(), self.mode)
    def __unicode__(self):
        return "%s" % self.sign()
    def sign(self):
        signer = TimestampSigner(salt=salt)
        return signer.sign(self.code)

def unsign_acode(acodestr):
        signer = TimestampSigner(salt=salt)
        try:
            code = signer.unsign(acodestr, max_age=(3600*24*14))
        except:
            print('invalid acode')
            code = None
        return code


# Create your models here.
