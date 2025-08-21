//Package tui
package tui

// Msg represents a message that can be sent to a model's Update function.
// It's an alias for any, allowing for any type of message.
type Msg any

// Cmd is a command that can be executed by the TUI runtime.
// It's a function that returns a message.
type Cmd func() Msg

// Model is the interface that all components in the TUI must implement.
type Model interface {
	// Init is the first function that will be called. It returns an optional
	// command to be executed.
	Init() Cmd

	// Update is called when a message is received. It returns the updated
	// model and an optional command.
	Update(msg Msg) (Model, Cmd)

	// View renders the model's state as a string.
	View() string
}

// --- Standard Messages ---

// WindowSizeMsg is sent when the terminal window is resized.
type WindowSizeMsg struct {
	Width  int
	Height int
}

// KeyType defines the type of a key press.
type KeyType int

// String returns a string representation of the key type.
func (k KeyType) String() string {
	return keyNames[k]
}

// KeyMsg is sent when a key is pressed.
type KeyMsg struct {
	Type KeyType

	// Runes holds the runes of the key press, if any.
	Runes []rune

	// Alt is true if the alt key was pressed.
	Alt bool
}

// --- Key Types ---

// This is a subset of bubbletea's KeyType for abstraction purposes.
const (
	KeyRunes KeyType = iota
	KeySpace
	KeyBackspace
	KeyDelete
	KeyEnter
	KeyEsc
	KeyTab
	KeyUp
	KeyDown
	KeyRight
	KeyLeft
	KeyCtrlC
	KeyCtrlD
)

var keyNames = map[KeyType]string{
	KeyRunes:     "runes",
	KeySpace:     "space",
	KeyBackspace: "backspace",
	KeyDelete:    "delete",
	KeyEnter:     "enter",
	KeyEsc:       "esc",
	KeyTab:       "tab",
	KeyUp:        "up",
	KeyDown:      "down",
	KeyRight:     "right",
	KeyLeft:      "left",
	KeyCtrlC:     "ctrl+c",
	KeyCtrlD:     "ctrl+d",
}
