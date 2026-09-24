package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
)

func newTestApp(t *testing.T, token string) http.Handler {
	t.Helper()
	db, err := openDB(context.Background(), filepath.Join(t.TempDir(), "test.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	return newHandler(&app{cfg: appConfig{Name: "test", AdminToken: token}, db: db})
}

func do(t *testing.T, h http.Handler, method, path, body, token string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	if token != "" {
		req.Header.Set("X-Admin-Token", token)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestHealthz(t *testing.T) {
	h := newTestApp(t, "")
	if rec := do(t, h, "GET", "/healthz", "", ""); rec.Code != http.StatusOK {
		t.Fatalf("healthz = %d, want 200", rec.Code)
	}
}

func TestEventsAreStoredAndCounted(t *testing.T) {
	h := newTestApp(t, "secret")
	for _, body := range []string{`{"event_type":"visit"}`, `{"event_type":"visit","subject":"home"}`, `{"event_type":"signup"}`} {
		if rec := do(t, h, "POST", "/events", body, ""); rec.Code != http.StatusCreated {
			t.Fatalf("POST %s = %d, want 201", body, rec.Code)
		}
	}

	rec := do(t, h, "GET", "/admin/summary", "", "secret")
	if rec.Code != http.StatusOK {
		t.Fatalf("summary = %d, want 200", rec.Code)
	}
	var out struct {
		Events map[string]int `json:"events"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&out); err != nil {
		t.Fatal(err)
	}
	if out.Events["visit"] != 2 || out.Events["signup"] != 1 {
		t.Fatalf("counts = %v, want visit=2 signup=1", out.Events)
	}
}

func TestEventsRejectBadInput(t *testing.T) {
	h := newTestApp(t, "")
	for _, body := range []string{`nope`, `{}`, `{"event_type":"   "}`, `{"event_type":"` + strings.Repeat("x", 65) + `"}`} {
		if rec := do(t, h, "POST", "/events", body, ""); rec.Code != http.StatusBadRequest {
			t.Fatalf("POST %q = %d, want 400", body, rec.Code)
		}
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
			h := newTestApp(t, tc.expected)
			if rec := do(t, h, "GET", "/admin/summary", "", tc.sent); rec.Code != tc.want {
				t.Fatalf("status = %d, want %d", rec.Code, tc.want)
			}
		})
	}
}
