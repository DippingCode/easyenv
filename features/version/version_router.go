// Package version define o roteamento interno da feature version.
package version

import (
	"os"

	"github.com/DippingCode/easyenv/features/version/data/services"
	"github.com/DippingCode/easyenv/features/version/domain/repositories"
	"github.com/DippingCode/easyenv/features/version/presenter/view"
	"github.com/DippingCode/easyenv/features/version/presenter/viewmodel"
)

// HandleRoute executa o fluxo da feature version com base em um comando recebido.
func HandleRoute(command string) {
	args := os.Args[1:] // pega todos os argumentos passados
	detailed := false

	// Verifica flags
	for _, arg := range args {
		if arg == "-d" || arg == "--detailed" {
			detailed = true
		}
	}

	service := services.NewVersionService()
	repo := repositories.NewVersionRepository(service)
	vm := viewmodel.NewVersionViewModel(repo)
	view.RenderVersion(vm, detailed)
}