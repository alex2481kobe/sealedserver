package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"time"
)

type appConfig struct {
	Name       string
	Addr       string
	AdminToken string
}

func main() {
	cfg := appConfig{
		Name:       env("APP_NAME", "go-service"),
		Addr:       env("APP_ADDR", "127.0.0.1:8090"),
		AdminToken: env("APP_ADMIN_TOKEN", ""),
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "service": cfg.Name})
	})
	mux.HandleFunc("GET /admin/summary", func(w http.ResponseWriter, r *http.Request) {
		if !authorized(r, cfg.AdminToken) {
			writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "unauthorized"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"service": cfg.Name,
			"now":     time.Now().UTC().Format(time.RFC3339),
		})
	})

	srv := &http.Server{
		Addr:              cfg.Addr,
		Handler:           secureHeaders(mux),
		ReadHeaderTimeout: 5 * time.Second,
	}

	slog.Info("starting service", "addr", cfg.Addr, "service", cfg.Name)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		slog.Error("service stopped", "err", err)
		os.Exit(1)
	}
}

func env(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

func authorized(r *http.Request, expected string) bool {
	return expected != "" && r.Header.Get("X-Admin-Token") == expected
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		next.ServeHTTP(w, r)
	})
}
