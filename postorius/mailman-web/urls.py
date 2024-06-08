# -*- coding: utf-8 -*-
# Copyright (C) 1998-2016 by the Free Software Foundation, Inc.
#
# This file is part of Postorius.
#
# Postorius is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# Postorius is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# Postorius.  If not, see <http://www.gnu.org/licenses/>.

from django.conf.urls import include
from django.contrib import admin
from django.urls import re_path, reverse_lazy
from django.views.generic import RedirectView

urlpatterns = [
    re_path(r'^$', RedirectView.as_view(
        url=reverse_lazy('list_index'),
        permanent=True)),
    re_path(r'postorius/', include('postorius.urls')),
    re_path(r'', include('django_mailman3.urls')),
    re_path(r'accounts/', include('allauth.urls')),
    # Django admin
    re_path(r'^admin/', admin.site.urls),
]
