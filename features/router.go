// Package features contém o roteador principal para todas as features.
package features

import (
	"fmt"

	"github.com/DippingCode/easyenv/features/version"
)

// Route direciona os comandos para a feature correspondente.
func Route(feature string, command string) {
	switch feature {
	case "-v", "--version", "version":
		version.HandleRoute(command)
	default:
		fmt.Println("Feature não encontrada:", feature)
	}
}