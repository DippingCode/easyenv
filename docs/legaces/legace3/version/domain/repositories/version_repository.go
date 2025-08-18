// Package repositories contém interfaces e implementações de repositórios.
// O repositório orquestra chamadas de serviços e entrega dados prontos para o domínio.
package repositories

import (
	"github.com/DippingCode/easyenv/features/version/data/services"
	"github.com/DippingCode/easyenv/features/version/domain/entities"
)

// VersionRepository define o contrato para manipulação da entidade Version.
type VersionRepository interface {
	GetVersion() (*entities.Version, error)
}

// versionRepositoryImpl implementa VersionRepository.
type versionRepositoryImpl struct {
	service *services.VersionService
}

// NewVersionRepository cria uma nova instância de repository.
func NewVersionRepository(service *services.VersionService) VersionRepository {
	return &versionRepositoryImpl{service: service}
}

// GetVersion obtém a versão atual da aplicação.
func (r *versionRepositoryImpl) GetVersion() (*entities.Version, error) {
	return r.service.GetVersion()
}