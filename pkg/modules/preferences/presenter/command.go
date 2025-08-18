// Package presenter
package presenter

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/DippingCode/easyenv/pkg/modules/preferences/data/services"
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/usecases"
)

// Variável para a flag `--theme`.
var themeFlag string

// NewPreferencesCmd cria o comando `preferences` e suas flags.
func NewPreferencesCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "preferences",
		Short: "Gerencia as preferências de usuário do EasyEnv.io.",
		Long:  `O comando preferences permite que você configure e gerencie as preferências do seu ambiente, como o tema da UI.`, 
		Run:   runPreferences,
	}

	// Adiciona a flag `--theme` e `-t`.
	cmd.Flags().StringVarP(&themeFlag, "theme", "t", "", "Define o tema do CLI. Use 'dark', 'light', 'default' ou 'menu' para abrir o menu interativo.")

	// Sobrescreve a ajuda padrão do Cobra para usar nossa UI de ajuda.
	cmd.SetHelpFunc(func(c *cobra.Command, a []string) {
		ShowHelp(c)
	})

	return cmd
}

// runPreferences é a função principal do comando `preferences`.
func runPreferences(cmd *cobra.Command, args []string) {
	// Obter o diretório de configuração do usuário.
	currentUser, err := user.Current()
	if err != nil {
		fmt.Printf("Erro ao obter o usuário: %v\n", err)
		os.Exit(1)
	}
	configPath := filepath.Join(currentUser.HomeDir, ".easyenv", "config.yml")
	
	// Inicializar o serviço de dados e o usecase.
	preferencesService := services.NewFilePreferencesService(configPath)
	preferencesUsecase := usecases.NewPreferencesUsecase(preferencesService)

	// A lógica do comando se baseia nas flags.
	if themeFlag != "" {
		if themeFlag == "menu" {
			ShowThemeMenu(preferencesUsecase)
		} else {
			err := preferencesUsecase.UpdateTheme(themeFlag)
			if err != nil {
				ShowError("Erro ao salvar o tema", err)
			} else {
				ShowSuccess(fmt.Sprintf("Tema definido para: %s", themeFlag))
			}
		}
		return
	}

	// Se nenhuma flag for especificada, mostre a ajuda.
	ShowHelp(cmd)
}
