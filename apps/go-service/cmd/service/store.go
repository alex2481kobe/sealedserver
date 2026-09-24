package main

import (
	"context"
	"database/sql"
	"net/url"
	"time"

	_ "modernc.org/sqlite"
)

// The schema is applied on every start. Changes must stay additive
// (new tables, new nullable columns) so an older binary can still run.
const schema = `
CREATE TABLE IF NOT EXISTS events (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	event_type TEXT NOT NULL,
	subject TEXT,
	created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_events_type_time ON events (event_type, created_at DESC);
`

func openDB(ctx context.Context, path string) (*sql.DB, error) {
	q := url.Values{}
	for _, pragma := range []string{"journal_mode(WAL)", "busy_timeout(5000)", "foreign_keys(ON)", "synchronous(NORMAL)"} {
		q.Add("_pragma", pragma)
	}
	db, err := sql.Open("sqlite", "file:"+path+"?"+q.Encode())
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(4)
	if _, err := db.ExecContext(ctx, schema); err != nil {
		db.Close()
		return nil, err
	}
	return db, nil
}

func recordEvent(ctx context.Context, db *sql.DB, eventType, subject string) error {
	var subj any
	if subject != "" {
		subj = subject
	}
	_, err := db.ExecContext(ctx,
		`INSERT INTO events (event_type, subject, created_at) VALUES (?, ?, ?)`,
		eventType, subj, time.Now().Unix())
	return err
}

func eventCounts(ctx context.Context, db *sql.DB) (map[string]int, error) {
	rows, err := db.QueryContext(ctx, `SELECT event_type, COUNT(*) FROM events GROUP BY event_type`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	counts := map[string]int{}
	for rows.Next() {
		var eventType string
		var n int
		if err := rows.Scan(&eventType, &n); err != nil {
			return nil, err
		}
		counts[eventType] = n
	}
	return counts, rows.Err()
}
