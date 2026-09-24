package main

import (
	"context"
	"crypto/subtle"
	"database/sql"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

type appConfig struct {
	Name       string
	Addr       string
	DBPath     string
	AdminToken string
}

type app struct {
	cfg appConfig
	db  *sql.DB
}

func main() {
	cfg := appConfig{
		Name:       env("APP_NAME", "go-service"),
		Addr:       env("APP_ADDR", "127.0.0.1:8081"),
		DBPath:     env("APP_DB_PATH", "app.sqlite"),
		AdminToken: env("APP_ADMIN_TOKEN", ""),
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := openDB(ctx, cfg.DBPath)
	if err != nil {
		slog.Error("open database", "path", cfg.DBPath, "err", err)
		os.Exit(1)
	}
	defer db.Close()

	srv := &http.Server{
		Addr:              cfg.Addr,
		Handler:           newHandler(&app{cfg: cfg, db: db}),
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	slog.Info("starting service", "addr", cfg.Addr, "service", cfg.Name, "db", cfg.DBPath)

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

func newHandler(a *app) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", a.healthz)
	mux.HandleFunc("POST /events", a.postEvent)
	mux.HandleFunc("GET /admin/summary", a.adminSummary)
	return secureHeaders(mux)
}

func (a *app) healthz(w http.ResponseWriter, r *http.Request) {
	if err := a.db.PingContext(r.Context()); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{"ok": false})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "service": a.cfg.Name})
}

func (a *app) postEvent(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	var in struct {
		EventType string `json:"event_type"`
		Subject   string `json:"subject"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "bad_json"})
		return
	}
	in.EventType = strings.TrimSpace(in.EventType)
	in.Subject = strings.TrimSpace(in.Subject)
	if in.EventType == "" || len(in.EventType) > 64 || len(in.Subject) > 128 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "bad_input"})
		return
	}
	if err := recordEvent(r.Context(), a.db, in.EventType, in.Subject); err != nil {
		slog.Error("record event", "err", err)
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "server_error"})
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"ok": true})
}

func (a *app) adminSummary(w http.ResponseWriter, r *http.Request) {
	if !authorized(r, a.cfg.AdminToken) {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "unauthorized"})
		return
	}
	counts, err := eventCounts(r.Context(), a.db)
	if err != nil {
		slog.Error("event counts", "err", err)
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "server_error"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"service": a.cfg.Name, "events": counts})
}

func env(key string, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
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
