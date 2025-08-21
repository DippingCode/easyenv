package tui

import tea "github.com/charmbracelet/bubbletea"

// BatchMsg is an internal message used to batch commands.
// We use a custom type to avoid exposing tea.BatchMsg directly.
type BatchMsg []Cmd

// Batch is a command that executes a list of commands.
func Batch(cmds ...Cmd) Cmd {
	// We filter out nil commands to avoid panics.
	var validCmds []Cmd
	for _, cmd := range cmds {
		if cmd != nil {
			validCmds = append(validCmds, cmd)
		}
	}
	if len(validCmds) == 0 {
		return nil
	}
	return func() Msg {
		return BatchMsg(validCmds)
	}
}

// toTeaCmds converts a slice of our generic Cmds to bubbletea commands.
// This will be used by the adapter.
func toTeaCmds(cmds []Cmd) []tea.Cmd {
	var teaCmds []tea.Cmd
	for _, cmd := range cmds {
		teaCmds = append(teaCmds, toTeaCmd(cmd))
	}
	return teaCmds
}
