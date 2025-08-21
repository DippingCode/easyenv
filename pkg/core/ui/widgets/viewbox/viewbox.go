package viewbox

import "github.com/DippingCode/easyenv/pkg/core/adapters/tui"

// ViewBox is the interface for a screen that can be loaded into a layout.
// It is an alias for tui.Model to ensure all screens adhere to the adapter's contract.
type ViewBox interface {
	tui.Model
}