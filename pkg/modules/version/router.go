//Package version
package version

import (
	"github.com/spf13/cobra"
	"github.com/DippingCode/easyenv/pkg/modules/version/presenter" // Import the presenter package
)

// GetRouter returns the Cobra command for the version module.
func GetRouter() *cobra.Command {
	return presenter.VersionCmd
}