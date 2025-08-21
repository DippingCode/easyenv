//Package adapters
package adapters

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
)

// Run takes a bubbletea model and runs it as a program.
// This function abstracts the bubbletea program's lifecycle management.
func Run(model tea.Model) {
	p := tea.NewProgram(model, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		fmt.Printf("Alas, there's been an error: %v", err)
		os.Exit(1)
	}
}
