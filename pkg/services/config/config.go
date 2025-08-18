// Package config
package config

import (
	"os"
	"path/filepath"
	"gopkg.in/yaml.v2"

	"github.com/DippingCode/easyenv/pkg/core/config"
)

type fileConfigManager struct {
    configPath string
}

func NewFileConfigManager() (config.ConfigManager, error) {
    userConfigDir, err := os.UserConfigDir()
    if err != nil {
        return nil, err
    }
    // Define o caminho para o arquivo de configuração.
    path := filepath.Join(userConfigDir, "easyenv", "config.yml")
    return &fileConfigManager{configPath: path}, nil
}

func (f *fileConfigManager) Load() (*config.UserPreferences, error) {
    data, err := os.ReadFile(f.configPath)
    if err != nil {
        // Se o arquivo não existir, retorna um objeto padrão.
        if os.IsNotExist(err) {
            return &config.UserPreferences{}, nil
        }
        return nil, err
    }

    var prefs config.UserPreferences
    err = yaml.Unmarshal(data, &prefs)
    if err != nil {
        return nil, err
    }

    return &prefs, nil
}

func (f *fileConfigManager) Save(prefs *config.UserPreferences) error {
    data, err := yaml.Marshal(prefs)
    if err != nil {
        return err
    }
    // Garante que o diretório exista antes de salvar.
    dir := filepath.Dir(f.configPath)
    if _, err := os.Stat(dir); os.IsNotExist(err) {
        os.MkdirAll(dir, 0755)
    }
    return os.WriteFile(f.configPath, data, 0644)
}

func (f *fileConfigManager) GetFilePath() (string, error) {
    return f.configPath, nil
}