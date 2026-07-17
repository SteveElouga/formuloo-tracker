"""Endpoint de santé — prouve la chaîne HTTP avant le GraphQL (FT-4)."""
from django.http import HttpRequest, JsonResponse


def sante(_request: HttpRequest) -> JsonResponse:
    return JsonResponse({"status": "SERVING"})
