package tui

import tea "github.com/charmbracelet/bubbletea"

// Quit is a command that signals the program to exit.
func Quit() Msg {
	return tea.Quit()
}
