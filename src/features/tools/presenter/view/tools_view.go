// Package view contém os componentes de apresentação para a feature de version,
// responsável por renderizar a saída de versão no CLI.
package view

import (
	"fmt"

	"github.com/DippingCode/easyenv/src/features/tools/domain/usecases"
)

func ToolsHelpView() {
	fmt.Println(`Uso:
  easyenv tools <subcomando>

Subcomandos:
  list        Lista o catálogo a partir de config/tools.yml

Exemplos:
  easyenv tools list`)
}

func ToolsListView(_ ...string) {
	tools, err := usecases.GetTools()
	if err != nil {
		fmt.Printf("Erro ao ler tools: %v\n", err)
		return
	}
	if len(tools) == 0 {
		fmt.Println("⚠️  Nenhuma ferramenta encontrada em config/tools.yml")
		return
	}
	for _, t := range tools {
		desc := t.Description
		if desc == "" {
			desc = "-"
		}
		fmt.Printf(" - %-22s  %s\n", t.Name, desc)
	}
}