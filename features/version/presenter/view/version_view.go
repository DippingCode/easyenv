// Package view contém a UI da feature version.
// Responsável apenas por renderizar dados.
package view

import (
	"fmt"
	"strings"

	"github.com/DippingCode/easyenv/features/version/presenter/viewmodel"
)

// RenderVersion exibe a versão de acordo com o modo detalhado ou simplificado.
func RenderVersion(vm *viewmodel.VersionViewModel, detailed bool) {
	v, err := vm.GetVersion()
	if err != nil {
		fmt.Println("Erro ao obter versão:", err)
		return
	}

	// Cabeçalho
	title := v.Title
	if strings.TrimSpace(title) == "" {
		title = fmt.Sprintf("Versão %s", safe(v.Number))
	}

	badge := strings.TrimSpace(v.Badge)
	build := strings.TrimSpace(v.Build)
	if build == "" && v.Meta.Build.Build != "" {
		build = v.Meta.Build.Build
	}

	fmt.Println("===================================")
	if badge != "" && build != "" {
		fmt.Printf(" EasyEnv - %s (%s) [%s]\n", title, build, badge)
	} else if build != "" {
		fmt.Printf(" EasyEnv - %s (%s)\n", title, build)
	} else if badge != "" {
		fmt.Printf(" EasyEnv - %s [%s]\n", title, badge)
	} else {
		fmt.Printf(" EasyEnv - %s\n", title)
	}
	fmt.Println("===================================")

	// Modo detalhado
	if !detailed {
		// Saída enxuta: número + build (quando houver)
		if v.Number != "" && build != "" {
			fmt.Printf("v%s (build %s)\n", v.Number, build)
		} else if v.Number != "" {
			fmt.Printf("v%s\n", v.Number)
		}
		return
	}

	// Added
	if len(v.Meta.Added) > 0 {
		fmt.Println("Adicionado:")
		for _, line := range v.Meta.Added {
			if s := strings.TrimSpace(line); s != "" {
				fmt.Printf(" - %s\n", s)
			}
		}
		fmt.Println()
	}

	// Changed
	if len(v.Meta.Changed) > 0 {
		fmt.Println("Alterado:")
		for _, line := range v.Meta.Changed {
			if s := strings.TrimSpace(line); s != "" {
				fmt.Printf(" - %s\n", s)
			}
		}
		fmt.Println()
	}

	// Notes
	if len(v.Meta.Notes) > 0 {
		fmt.Println("Notas:")
		for _, line := range v.Meta.Notes {
			if s := strings.TrimSpace(line); s != "" {
				fmt.Printf(" - %s\n", s)
			}
		}
		fmt.Println()
	}

	// Next Steps
	if len(v.Meta.NextSteps) > 0 {
		fmt.Println("Próximos passos:")
		for _, line := range v.Meta.NextSteps {
			if s := strings.TrimSpace(line); s != "" {
				fmt.Printf(" - %s\n", s)
			}
		}
		fmt.Println()
	}

	// Build details
	if v.Meta.Build.Build != "" || v.Meta.Build.Tag != "" || v.Meta.Build.Commit != "" {
		fmt.Println("Build Details:")
		if v.Meta.Build.Build != "" {
			fmt.Printf(" - Build: %s\n", v.Meta.Build.Build)
		}
		if v.Meta.Build.Tag != "" {
			fmt.Printf(" - Tag:   %s\n", v.Meta.Build.Tag)
		}
		if v.Meta.Build.Commit != "" {
			fmt.Printf(" - Commit:%s\n", prefixedSpace(v.Meta.Build.Commit))
		}
	}
}

func safe(s string) string {
	return strings.TrimSpace(s)
}

func prefixedSpace(s string) string {
	if strings.HasPrefix(s, " ") {
		return s
	}
	return " " + s
}