package router

import "github.com/spf13/cobra"

// IRouter defines the interface for a module router.
// All modules that expose commands to the CLI should implement this interface.
type IRouter interface {
	GetCommand() *cobra.Command
}
