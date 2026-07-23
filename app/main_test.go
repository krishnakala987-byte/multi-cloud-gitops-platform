package main

import (
	"os"
	"testing"
)

// Minimal CI gate: verifies env fallback logic used for cloud identity labels.
func TestGetenvFallback(t *testing.T) {
	os.Unsetenv("CLOUD_PROVIDER")
	if got := getenv("CLOUD_PROVIDER", "unknown"); got != "unknown" {
		t.Fatalf("expected fallback 'unknown', got %q", got)
	}
	os.Setenv("CLOUD_PROVIDER", "aws")
	defer os.Unsetenv("CLOUD_PROVIDER")
	if got := getenv("CLOUD_PROVIDER", "unknown"); got != "aws" {
		t.Fatalf("expected 'aws', got %q", got)
	}
}
