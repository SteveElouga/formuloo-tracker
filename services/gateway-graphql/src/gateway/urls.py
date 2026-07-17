"""Routage — /sante/ au FT-1 ; /graphql arrive au FT-4."""
from django.urls import path

from gateway.health import sante

urlpatterns = [
    path("sante/", sante, name="sante"),
]
