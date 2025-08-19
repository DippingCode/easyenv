// Package presenter provides UI-related functions for the version module.
package presenter

import (
	"fmt"

	"github.com/DippingCode/easyenv/pkg/modules/version/domain/entities"
)

// PrintVersion prints the version information to the console.
func PrintVersion(version *entities.Version) {
	fmt.Printf("v%s+%s\n", version.Number, version.Meta.Build.Build)
}

// PrintDetailedVersion prints the detailed version information to the console.
func PrintDetailedVersion(version *entities.Version) {
	fmt.Printf("EasyEnv v.%s build %s\n\n", version.Number, version.Meta.Build.Build)

	if len(version.Meta.Changed) > 0 {
		fmt.Println("Changed")
		for _, item := range version.Meta.Changed {
			fmt.Printf("- %s\n", item)
		}
		fmt.Println() // Add a newline for spacing
	}

	if len(version.Meta.Notes) > 0 {
		fmt.Println("Notes")
		for _, item := range version.Meta.Notes {
			fmt.Printf("- %s\n", item)
		}
		fmt.Println() // Add a newline for spacing
	}

	if len(version.Meta.NextSteps) > 0 {
		fmt.Println("Next Steps")
		for _, item := range version.Meta.NextSteps {
			fmt.Printf("- %s\n", item)
		}
		fmt.Println() // Add a newline for spacing
	}
}
