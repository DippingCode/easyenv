package main

import (
	"fmt"
	"os"

	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/shell"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "EasyEnv.io - Gerenciador de ambiente de desenvolvimento",
	Long:  `A TUI interativa para gerenciar seus ambientes de desenvolvimento.`, 
	RunE: func(cmd *cobra.Command, args []string) error {
		appShell := shell.New()

		if _, err := tui.Run(appShell, tui.WithAltScreen(), tui.WithMouseCellMotion()); err != nil {
			fmt.Fprintf(os.Stderr, "Error running program: %v\n", err)
			return err
		}
		return nil
	},

}

// Execute is the main entry point for the cobra CLI.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		// Cobra already prints the error, so we just exit.
		os.Exit(1)
	}
}
