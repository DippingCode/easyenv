package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"

	"github.com/spf13/cobra"

	// Importações dos roteadores
	"github.com/DippingCode/easyenv/pkg/core/config/themeloaderservice"
	interactiveshell "github.com/DippingCode/easyenv/pkg/modules/interactiveshell/presenter"
	"github.com/DippingCode/easyenv/pkg/modules/preferences"
)

var rootCmd = &cobra.Command{
	Use:   "eye",
	Short: "Gerencia seu ambiente de desenvolvimento.",
	Long:  `O CLI do EasyEnv.io. Digite 'exit' para sair.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Passo 1: Obter os caminhos dos arquivos.
		currentUser, err := user.Current()
		if err != nil {
			fmt.Println("Erro ao obter o diretório do usuário:", err)
			os.Exit(1)
		}
		userConfigPath := filepath.Join(currentUser.HomeDir, ".easyenv", "config.yml")
		themesAssetsPath := "assets/themes/template.yml"

		// Passo 2: Instanciar e usar o serviço de carregamento de temas.
		themeLoader := themeloaderservice.NewThemeLoaderService(userConfigPath, themesAssetsPath)
		currentTheme, err := themeLoader.LoadTheme()
		if err != nil {
			fmt.Println("Erro ao carregar o tema:", err)
			os.Exit(1)
		}

		// Passo 3: Passar o tema carregado para a função de execução do interactive_shell.
		// AQUI ESTÁ A CORREÇÃO: a variável 'currentTheme' é passada como argumento.
		interactiveshell.Run(args, currentTheme)
	},
}


// init() do Cobra para registrar subcomandos.
func init() {
	// Apenas para que o Cobra reconheça os comandos,
	// mas a execução será gerenciada internamente pelo shell.
	rootCmd.AddCommand(preferences.GetRouter())
	// rootCmd.AddCommand(version.GetRouter())
}

// Execute adiciona todos os comandos filhos ao comando raiz
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}