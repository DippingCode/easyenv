// Package usecases
package usecases

import (
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/entities"
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/services"
)

// PreferencesUsecase lida com a lógica de negócio para as preferências.
type PreferencesUsecase struct {
	service services.PreferencesService
}

// NewPreferencesUsecase cria uma nova instância de PreferencesUsecase.
func NewPreferencesUsecase(service services.PreferencesService) *PreferencesUsecase {
	return &PreferencesUsecase{service: service}
}

// GetPreferences carrega as preferências do usuário.
func (uc *PreferencesUsecase) GetPreferences() (*entities.Preferences, error) {
	return uc.service.LoadPreferences()
}

// UpdateTheme atualiza o tema nas preferências do usuário.
func (uc *PreferencesUsecase) UpdateTheme(theme string) error {
	// Carrega as preferências existentes para não sobrescrever outros campos.
	prefs, err := uc.service.LoadPreferences()
	if err != nil {
		return err
	}

	// Atualiza apenas o campo do tema
	prefs.Theme = theme

	// Salva as preferências atualizadas
	return uc.service.SavePreferences(prefs)
}