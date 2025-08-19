// Package input provides an input component for the design system.
package input

import (
	"fmt"

	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/interfaces"
	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/themes"
)

// Input represents a text input field component.
type Input struct {
	Placeholder string
	Value       string
	Theme       themes.Theme
}

// NewInput creates a new Input component.
func NewInput(placeholder string, theme themes.Theme) *Input {
	return &Input{Placeholder: placeholder, Theme: theme}
}

// SetValue sets the current value of the input field.
func (i *Input) SetValue(value string) {
	i.Value = value
}

// Render returns the string representation of the Input component.
func (i *Input) Render() string {
	// Basic rendering for a terminal input field
	displayValue := i.Value
	if displayValue == "" {
		displayValue = i.Placeholder
	}
	return fmt.Sprintf("[%s%s%s]", i.Theme.BackgroundColor(), displayValue, i.Theme.TextColor())
}

// Ensure Input implements the interfaces.Component interface.
var _ interfaces.Component = (*Input)(nil)
