// Package features contém as features do projeto,
package features

import (
	"fmt"
	"os"

	"github.com/DippingCode/easyenv/src/features/help/presenter/view"
	versionview "github.com/DippingCode/easyenv/src/features/version/presenter/view"
	toolview "github.com/DippingCode/easyenv/src/features/tools/presenter/view"
)

func Dispatch(argv []string) {
	cmd := "help"
	if len(argv) > 0 && argv[0] != "" {
		cmd = argv[0]
	}

	switch cmd {
	case "help", "-h", "--help":
		view.HelpView()
	case "version", "-v", "--version":
		detailed := false
		for _, a := range argv[1:] {
			if a == "--detailed" {
				detailed = true
				break
			}
		}
		versionview.VersionView(detailed)
	case "tools":
		if len(argv) == 1 {
			toolview.ToolsHelpView()
			return
		}
		sub := argv[1]
		switch sub {
		case "list":
			toolview.ToolsListView(argv[2:]...)
		default:
			fmt.Println("Uso:")
			toolview.ToolsHelpView()
		}
	default:
		fmt.Printf("Comando desconhecido: %s\n\n", cmd)
		view.HelpView()
		os.Exit(1)
	}
}