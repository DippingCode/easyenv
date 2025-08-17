// Package datasources contém os datasources do projeto
package datasources

import (
	"fmt"
	"os"

	"github.com/DippingCode/easyenv/src/core/config"
	"github.com/DippingCode/easyenv/src/features/tools/domain/entities"
	"gopkg.in/yaml.v3"
)

type toolsYAML struct {
	Tools []entities.Tool `yaml:"tools"`
}

func ReadAllTools() ([]entities.Tool, error) {
	paths, err := config.ResolvePaths()
	if err != nil {
		return nil, err
	}
	b, err := os.ReadFile(paths.ToolsYAML)
	if err != nil {
		if os.IsNotExist(err) {
			return []entities.Tool{}, nil
		}
		return nil, fmt.Errorf("read tools.yml: %w", err)
	}
	var cat toolsYAML
	if err := yaml.Unmarshal(b, &cat); err != nil {
		return nil, fmt.Errorf("parse tools.yml: %w", err)
	}
	return cat.Tools, nil
}