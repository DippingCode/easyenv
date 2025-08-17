// Package view contém os componentes de apresentação para a feature de version,
// responsável por renderizar a saída de versão no CLI.
package view

import "fmt"

func HelpView() {
	fmt.Println()
	fmt.Println("┌─────────────────────────────────────────────────────┐")
	fmt.Println("│                    EasyEnv - Help                  │")
	fmt.Println("└─────────────────────────────────────────────────────┘")
	fmt.Println("Uso:")
	fmt.Println("  easyenv <comando> [opções]")
	fmt.Println()
	fmt.Println("Comandos:")
	fmt.Println("  help                  Mostra esta ajuda")
	fmt.Println("  version [--detailed]  Exibe versão/build atual (lê dev_log.yml)")
	fmt.Println("  tools list            Lista ferramentas do config/tools.yml")
	fmt.Println()
	fmt.Println("Exemplos:")
	fmt.Println("  easyenv version")
	fmt.Println("  easyenv tools list")
}