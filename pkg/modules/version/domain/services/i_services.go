package services

import "github.com/DippingCode/easyenv/pkg/modules/version/domain/entities"

// IVersionService defines the interface for the version service.
type IVersionService interface {
	GetVersion() (*entities.Version, error)
}
