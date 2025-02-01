# -*- coding: utf-8 -*-
# Copyright (C) 2023 by the Free Software Foundation, Inc.
#
# This file is part of mailman-web.
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
from django.urls import path, reverse_lazy
from django.views.generic import RedirectView

urlpatterns = [
    path(
        "",
        RedirectView.as_view(url=reverse_lazy("list_index"), permanent=True),
    ),
    # Include alternate Postorius and HyperKitty URLs.
    path("postorius/", include("postorius.urls")),
    path("hyperkitty/", include("hyperkitty.urls")),
    # Order counts for various links. Put the above first and the following
    # after so the suggested Apache config still works.
    path("mailman3/", include("postorius.urls")),
    path("archives/", include("hyperkitty.urls")),
    path("", include("django_mailman3.urls")),
    path("accounts/", include("allauth.urls")),
    path("admin/", admin.site.urls),
]
