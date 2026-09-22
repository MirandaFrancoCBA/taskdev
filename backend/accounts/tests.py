from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AuthenticationTests(APITestCase):
    def test_register_hashes_password(self):
        response = self.client.post("/api/auth/register/", {"username": "franco", "email": "franco@example.com", "password": "strong-pass-123"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(username="franco")
        self.assertTrue(user.check_password("strong-pass-123"))

    def test_login_and_me(self):
        User.objects.create_user(username="member", password="strong-pass-123")
        login = self.client.post("/api/auth/login/", {"username": "member", "password": "strong-pass-123"}, format="json")
        self.assertEqual(login.status_code, status.HTTP_200_OK)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        me = self.client.get("/api/auth/me/")
        self.assertEqual(me.status_code, status.HTTP_200_OK)
        self.assertEqual(me.data["username"], "member")

    def test_me_requires_authentication(self):
        response = self.client.get("/api/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
