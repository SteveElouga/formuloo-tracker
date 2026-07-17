"""Smoke test — la chaîne HTTP répond (FT-1). Test-du-test de la CI."""


def test_sante_repond_serving(client):
    response = client.get("/sante/")
    assert response.status_code == 200
    assert response.json() == {"status": "SERVING"}
