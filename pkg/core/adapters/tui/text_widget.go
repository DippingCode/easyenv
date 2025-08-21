package tui

// TextWidget is an interface for components that primarily display text.
// It embeds the base Component interface.
type TextWidget interface {
	Component
	SetText(text string)
	// TextStyle returns the style applied to the text content.
	// This allows for more specific text styling beyond the component's overall style.
	TextStyle() Style
}
