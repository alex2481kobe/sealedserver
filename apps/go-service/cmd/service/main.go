package main

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
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
		Addr:       env("APP_ADDR", "127.0.0.1:8081"),
		AdminToken: env("APP_ADMIN_TOKEN", ""),
	}

	srv := &http.Server{
		Addr:              cfg.Addr,
		Handler:           newHandler(cfg),
		ReadHeaderTimeout: 5 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	slog.Info("starting service", "addr", cfg.Addr, "service", cfg.Name)

	select {
	case err := <-errc:
		if !errors.Is(err, http.ErrServerClosed) {
			slog.Error("service stopped", "err", err)
			os.Exit(1)
		}
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := srv.Shutdown(shutdownCtx); err != nil {
			slog.Error("shutdown", "err", err)
		}
	}
}

func newHandler(cfg appConfig) http.Handler {
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
	return secureHeaders(mux)
}

func env(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

func authorized(r *http.Request, expected string) bool {
	got := r.Header.Get("X-Admin-Token")
	return expected != "" && subtle.ConstantTimeCompare([]byte(got), []byte(expected)) == 1
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
