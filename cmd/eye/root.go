package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/DippingCode/easyenv/pkg/modules/version/presenter" // Import the presenter package
)

var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "EasyEnv.io CLI",
	Long:  `A fast and flexible CLI for managing development environments.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Default action when no command is provided
		cmd.Help() // Display help when no subcommand is given
	},
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.eye.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	// rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	rootCmd.AddCommand(presenter.VersionCmd)
}

// AddCommand allows adding new commands to the root command.
func AddCommand(cmd *cobra.Command) {
	rootCmd.AddCommand(cmd)
}