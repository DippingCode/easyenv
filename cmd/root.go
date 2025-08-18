//Package eye é a raiz do CLI EasyEnv.io. Ele lida com a inicialização e o roteamento dos comandos.
package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	
	// Importações dos roteadores de cada módulo de primeiro nível.
	"github.com/DippingCode/easyenv/pkg/modules/version" 
    "github.com/DippingCode/easyenv/pkg/modules/preferences"
)

// rootCmd é o comando raiz para o CLI.
var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "EasyEnv.io CLI",
	Long:  `Um CLI para gerenciar seu ambiente de desenvolvimento.`,
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

// Execute adiciona todos os comandos filhos ao comando raiz e os executa.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

// init é a função que registra todos os roteadores dos módulos.
func init() {
	// Registro dos roteadores de módulo.
	rootCmd.AddCommand(version.GetRouter())
    rootCmd.AddCommand(preferences.GetRouter())

    // A lógica para adicionar flags globais (persistent flags) deve ser feita aqui.
    // Exemplo:
    // rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.easyenv.yaml)")
}