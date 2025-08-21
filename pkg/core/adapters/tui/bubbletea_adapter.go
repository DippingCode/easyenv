//Package tui
package tui

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
)

// --- Public API ---

// ProgramOption is a functional option for configuring the TUI program.
// It's a wrapper around bubbletea's ProgramOption.
type ProgramOption func() tea.ProgramOption

// WithAltScreen is an option to run the program in the alternate screen buffer.
func WithAltScreen() ProgramOption {
	return tea.WithAltScreen
}

// WithMouseCellMotion is an option to enable mouse motion tracking.
func WithMouseCellMotion() ProgramOption {
	return tea.WithMouseCellMotion
}

// Run starts and runs the TUI program for the given model.
func Run(model Model, opts ...ProgramOption) (Model, error) {
	// Convert our generic options to bubbletea options
	teaOpts := make([]tea.ProgramOption, len(opts))
	for i, opt := range opts {
		teaOpts[i] = opt()
	}

	// Create the bubbletea program with our adapter
	p := tea.NewProgram(&modelAdapter{inner: model}, teaOpts...)

	// Run the program
	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error running program: %v\n", err)
		os.Exit(1)
		return nil, err // Should not be reached
	}

	// Return the final inner model
	return finalModel.(*modelAdapter).inner, nil
}

// --- Adapter Internals ---

// modelAdapter wraps our generic tui.Model to make it compatible with bubbletea.
// It implements the tea.Model interface.
type modelAdapter struct {
	inner Model
}

// Init translates the Init call.
func (a *modelAdapter) Init() tea.Cmd {
	return toTeaCmd(a.inner.Init())
}

// Update translates the Update call.
func (a *modelAdapter) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	// Translate incoming message from bubbletea to our generic message
	translatedMsg := fromTeaMsg(msg)

	// Call the inner model's Update function
	newInnerModel, newCmd := a.inner.Update(translatedMsg)

	// Update the inner model
	a.inner = newInnerModel

	// Return the adapter and the translated command
	return a, toTeaCmd(newCmd)
}

// View translates the View call.
func (a *modelAdapter) View() string {
	return a.inner.View()
}

// --- Type Translation Helpers ---

// toTeaCmd converts our generic Cmd to a bubbletea command.
func toTeaCmd(cmd Cmd) tea.Cmd {
	if cmd == nil {
		return nil
	}
	return func() tea.Msg {
		// When the command is run, it produces a generic Msg.
		msg := cmd()

		// If the message is a batch message, we unpack it and convert it to a tea.Batch.
		if b, ok := msg.(BatchMsg); ok {
			return tea.Batch(toTeaCmds(b)...)
		}

		// Otherwise, we return the message directly.
		return msg
	}
}

// fromTeaMsg converts a bubbletea message to our generic message.
func fromTeaMsg(msg tea.Msg) Msg {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		return WindowSizeMsg{Width: msg.Width, Height: msg.Height}
	case tea.KeyMsg:
		return KeyMsg{
			Type:  fromTeaKeyType(msg.Type),
			Runes: msg.Runes,
			Alt:   msg.Alt,
		}
	default:
		// For any other message type, we pass it through directly.
		return msg
	}
}

// fromTeaKeyType converts a bubbletea key type to our generic key type.
func fromTeaKeyType(t tea.KeyType) KeyType {
	switch t {
	case tea.KeyRunes: return KeyRunes
	case tea.KeySpace: return KeySpace
	case tea.KeyBackspace: return KeyBackspace
	case tea.KeyDelete: return KeyDelete
	case tea.KeyEnter: return KeyEnter
	case tea.KeyEscape: return KeyEsc
	case tea.KeyTab: return KeyTab
	case tea.KeyUp: return KeyUp
	case tea.KeyDown: return KeyDown
	case tea.KeyRight: return KeyRight
	case tea.KeyLeft: return KeyLeft
	case tea.KeyCtrlC: return KeyCtrlC
	case tea.KeyCtrlD: return KeyCtrlD
	default:
		// For simplicity, we can return a known type for unhandled keys.
		// A more robust implementation could expand the KeyType enum.
		return KeyRunes
	}
}
