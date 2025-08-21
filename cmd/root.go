package main

import (
	"os"

	"github.com/DippingCode/easyenv/pkg/core/ui/adapters"
	"github.com/DippingCode/easyenv/pkg/core/ui/shell"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "EasyEnv.io - Gerenciador de ambiente de desenvolvimento",
	Long:  `A TUI interativa para gerenciar seus ambientes de desenvolvimento.`,
	// We use RunE to handle errors returned from the TUI.
	RunE: func(cmd *cobra.Command, args []string) error {
		
		// Create the root model, passing the theme manager.
		appShell := shell.New()

		// Run the application using the adapter.
		adapters.Run(appShell)

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
