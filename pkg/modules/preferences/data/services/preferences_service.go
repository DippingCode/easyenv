// Package services
package services

import (
	"os"
	"path/filepath"
	"gopkg.in/yaml.v2"

	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/entities"
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/services"
)

// filePreferencesService implementa a interface domain/services.PreferencesService
type filePreferencesService struct {
	configPath string
}

// NewFilePreferencesService cria uma nova instância do serviço de preferências.
func NewFilePreferencesService(configPath string) services.PreferencesService {
	return &filePreferencesService{configPath: configPath}
}

func (s *filePreferencesService) LoadPreferences() (*entities.Preferences, error) {
	data, err := os.ReadFile(s.configPath)
	if err != nil {
		// Se o arquivo não existir, retorna um objeto padrão para evitar erro.
		if os.IsNotExist(err) {
			return &entities.Preferences{}, nil
		}
		return nil, err
	}

	var prefs entities.Preferences
	if err := yaml.Unmarshal(data, &prefs); err != nil {
		return nil, err
	}
	return &prefs, nil
}

func (s *filePreferencesService) SavePreferences(prefs *entities.Preferences) error {
	data, err := yaml.Marshal(prefs)
	if err != nil {
		return err
	}

	// Garante que o diretório exista antes de salvar.
	dir := filepath.Dir(s.configPath)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return err
		}
	}

	return os.WriteFile(s.configPath, data, 0644)
}