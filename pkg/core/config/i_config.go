//Package config
package config

// ConfigManager define a interface para gerenciar a configuração.
type ConfigManager interface {
    Load() (*UserPreferences, error)
    Save(prefs *UserPreferences) error
    GetFilePath() (string, error)
}