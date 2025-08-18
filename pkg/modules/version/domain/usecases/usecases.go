package usecases

import (
	"github.com/DippingCode/easyenv/pkg/modules/version/domain/entities"
	"github.com/DippingCode/easyenv/pkg/modules/version/domain/services"
)

// VersionUseCase is the use case for version-related operations.
type VersionUseCase struct {
	service services.IVersionService
}

// NewVersionUseCase creates a new VersionUseCase.
func NewVersionUseCase(service services.IVersionService) *VersionUseCase {
	return &VersionUseCase{
		service: service,
	}
}

// GetVersion returns the version of the application.
func (uc *VersionUseCase) GetVersion() (*entities.Version, error) {
	return uc.service.GetVersion()
}
