// Package button provides a button component for the design system.
package button

import (
	"fmt"

	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/interfaces"
	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/themes"
)

// Button represents a clickable button component.
type Button struct {
	Label string
	Theme themes.Theme
}

// NewButton creates a new Button component.
func NewButton(label string, theme themes.Theme) *Button {
	return &Button{Label: label, Theme: theme}
}

// Render returns the string representation of the Button component.
func (b *Button) Render() string {
	// Basic rendering for a terminal button, using theme colors
	return fmt.Sprintf("[%s%s%s]", b.Theme.PrimaryColor(), b.Label, b.Theme.TextColor())
}

// Ensure Button implements the interfaces.Component interface.
var _ interfaces.Component = (*Button)(nil)
