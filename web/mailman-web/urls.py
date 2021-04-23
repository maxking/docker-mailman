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

import os
from django.conf.urls import include, url
from django.contrib import admin
from django.urls import reverse_lazy
from django.views.generic import RedirectView


base_path = os.environ.get('BASE_PATH', '')

urlpatterns = [
    url(f'^{base_path}$', RedirectView.as_view(
        url=reverse_lazy('list_index'),
        permanent=True)),
    url(f'^{base_path}postorius/', include('postorius.urls')),
    url(f'^{base_path}hyperkitty/', include('hyperkitty.urls')),
    url(f'{base_path}', include('django_mailman3.urls')),
    url(f'^{base_path}accounts/', include('allauth.urls')),
    # Django admin
    url(f'^{base_path}admin/', admin.site.urls),
]
