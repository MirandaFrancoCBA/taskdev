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


    def test_logout_blacklists_refresh_token(self):
        User.objects.create_user(username="logout-member", password="strong-pass-123")
        login = self.client.post("/api/auth/login/", {"username": "logout-member", "password": "strong-pass-123"}, format="json")
        access = login.data["access"]
        refresh = login.data["refresh"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")

        logout = self.client.post("/api/auth/logout/", {"refresh": refresh}, format="json")
        self.assertEqual(logout.status_code, status.HTTP_204_NO_CONTENT)

        self.client.credentials()
        retry = self.client.post("/api/auth/refresh/", {"refresh": refresh}, format="json")
        self.assertEqual(retry.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_refresh_rotates_token_and_blacklists_previous_refresh(self):
        User.objects.create_user(username="rotate-member", password="strong-pass-123")
        login = self.client.post("/api/auth/login/", {"username": "rotate-member", "password": "strong-pass-123"}, format="json")
        original = login.data["refresh"]

        rotated = self.client.post("/api/auth/refresh/", {"refresh": original}, format="json")
        self.assertEqual(rotated.status_code, status.HTTP_200_OK)
        self.assertIn("refresh", rotated.data)

        retry = self.client.post("/api/auth/refresh/", {"refresh": original}, format="json")
        self.assertEqual(retry.status_code, status.HTTP_401_UNAUTHORIZED)
