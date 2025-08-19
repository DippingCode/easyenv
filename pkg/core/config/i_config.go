// Package config provides core configuration structures and interfaces for the EasyEnv application.
package config

// ConfigManager define a interface para gerenciar a configuração.
type ConfigManager interface {
	Load() (*UserPreferences, error)
	Save(prefs *UserPreferences) error
	GetFilePath() (string, error)
}
