// Package interfaces defines common interfaces for UI components in the design system.
package interfaces

// Component defines the basic interface for all UI components in the design system.
type Component interface {
	Render() string
}
