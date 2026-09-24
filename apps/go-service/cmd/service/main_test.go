package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func request(t *testing.T, h http.Handler, path string, token string) int {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, path, nil)
	if token != "" {
		req.Header.Set("X-Admin-Token", token)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec.Code
}

func TestHealthz(t *testing.T) {
	h := newHandler(appConfig{Name: "test"})
	if code := request(t, h, "/healthz", ""); code != http.StatusOK {
		t.Fatalf("healthz = %d, want 200", code)
	}
}

func TestAdminSummaryToken(t *testing.T) {
	cases := []struct {
		name     string
		expected string
		sent     string
		want     int
	}{
		{"no token configured", "", "", http.StatusUnauthorized},
		{"missing token", "secret", "", http.StatusUnauthorized},
		{"wrong token", "secret", "nope", http.StatusUnauthorized},
		{"right token", "secret", "secret", http.StatusOK},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			h := newHandler(appConfig{Name: "test", AdminToken: tc.expected})
			if code := request(t, h, "/admin/summary", tc.sent); code != tc.want {
				t.Fatalf("status = %d, want %d", code, tc.want)
			}
		})
	}
}
