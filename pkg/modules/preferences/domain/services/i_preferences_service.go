// Package services defines interfaces for preference-related operations.
package services

import "github.com/DippingCode/easyenv/pkg/modules/preferences/domain/entities"

// PreferencesService define a interface para interagir com o repositório de preferências.
type PreferencesService interface {
	LoadPreferences() (*entities.Preferences, error)
	SavePreferences(prefs *entities.Preferences) error
}
