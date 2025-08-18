// Package viewmodel contém a lógica de orquestração entre domain/repository e view.
package viewmodel

import (
	"github.com/DippingCode/easyenv/features/version/domain/entities"
	"github.com/DippingCode/easyenv/features/version/domain/repositories"
)

// VersionViewModel orquestra a comunicação entre a camada de domínio e a view.
type VersionViewModel struct {
	repo repositories.VersionRepository
}

// NewVersionViewModel cria um novo viewmodel.
func NewVersionViewModel(repo repositories.VersionRepository) *VersionViewModel {
	return &VersionViewModel{repo: repo}
}

// GetVersion obtém a versão atual a partir do repositório.
func (vm *VersionViewModel) GetVersion()  (*entities.Version, error) {
	return vm.repo.GetVersion()
}