// Package usecases contém os casos de uso da domain.
package usecases

import (
	"github.com/DippingCode/easyenv/src/features/tools/data/datasources"
	"github.com/DippingCode/easyenv/src/features/tools/domain/entities"
)

func GetTools() ([]entities.Tool, error) {
	return datasources.ReadAllTools()
}