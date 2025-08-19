package presenter

import (
	"github.com/spf13/cobra"

	"github.com/DippingCode/easyenv/pkg/modules/version/data/services"
	"github.com/DippingCode/easyenv/pkg/modules/version/domain/usecases"
)

var detailed bool

// VersionCmd represents the version command
var VersionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of eye",
	Long:  `All software has versions. This is eye's`,
	RunE: func(cmd *cobra.Command, args []string) error {
		service := services.NewVersionService()
		usecase := usecases.NewVersionUseCase(service)

		version, err := usecase.GetVersion()
		if err != nil {
			return err
		}

		if detailed {
			PrintDetailedVersion(version) // Call the function from ui.go
		} else {
			PrintVersion(version) // Call the function from ui.go
		}

		return nil
	},
}

func init() {
	VersionCmd.Flags().BoolVarP(&detailed, "detailed", "d", false, "Show detailed version information")
}
