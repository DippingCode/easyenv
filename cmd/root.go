package main

import (
	"fmt"
	"os"

	"github.com/DippingCode/easyenv/pkg/core/ui/shell"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "EasyEnv.io - Gerenciador de ambiente de desenvolvimento",
	Long:  `A TUI interativa para gerenciar seus ambientes de desenvolvimento.`,
	// We use RunE to handle errors returned from the TUI.
	RunE: func(cmd *cobra.Command, args []string) error {
		// TODO: Implement theme loading and pass it to the shell.

		// Create the root model.
		appShell := shell.New()

		// Create and run the bubbletea program.
		p := tea.NewProgram(appShell, tea.WithAltScreen(), tea.WithMouseCellMotion())

		if _, err := p.Run(); err != nil {
			// If there's an error, we'll print it to the console.
			return fmt.Errorf("erro ao executar a aplicação: %w", err)
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
