// Package config provides core configuration structures and interfaces for the EasyEnv application.
package config

// UserPreferences representa as configurações do usuário.
type UserPreferences struct {
	Theme string `yaml:"theme"`
	// Adicione outros campos, como:
	// DefaultStack string `yaml:"default_stack"`
	// TelemetryEnabled bool `yaml:"telemetry_enabled"`
}
