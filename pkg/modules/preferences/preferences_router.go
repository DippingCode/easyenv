// Package preferences implementa a feature para gerenciar as preferências do usuário.
// O router do pacote lida com o command 'preferences' e seus subcommands.
package preferences

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/DippingCode/easyenv/pkg/modules/preferences/data/services"
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/usecases"
	presenter "github.com/DippingCode/easyenv/pkg/modules/preferences/presenter/themepreference"
)

// Define as variáveis de flags do módulo
var themeFlag string

// GetRouter cria e configura o roteador para o módulo `preferences`.
func GetRouter() *cobra.Command {
	preferencesCmd := &cobra.Command{
		Use:   "preferences",
		Short: "Gerencia as preferências de usuário do EasyEnv.io.",
		Run:   runPreferences,
	}

	// Adiciona a flag `--theme`
	preferencesCmd.Flags().StringVarP(&themeFlag, "theme", "t", "", "Seleciona o tema do CLI. Use 'dark', 'light' ou 'menu'.")

	// Sobrescreve o help do Cobra para usar nossa UI de ajuda.
	preferencesCmd.SetHelpFunc(func(c *cobra.Command, a []string) {
		presenter.ShowHelp(c)
	})

	return preferencesCmd
}

// runPreferences é a função principal do command `preferences`.
func runPreferences(cmd *cobra.Command, args []string) {
	// Obter o diretório de configuração do usuário.
	currentUser, err := user.Current()
	if err != nil {
		presenter.ShowError("Erro ao obter o usuário.", err)
		os.Exit(1)
	}
	configPath := filepath.Join(currentUser.HomeDir, ".easyenv", "config.yml")

	// Inicializar o serviço e o usecase.
	preferencesService := services.NewFilePreferencesService(configPath)
	preferencesUsecase := usecases.NewPreferencesUsecase(preferencesService)

	// A lógica do command se baseia nas flags.
	if themeFlag != "" {
		if themeFlag == "menu" {
			presenter.ShowThemeMenu(preferencesUsecase)
		} else {
			err := preferencesUsecase.UpdateTheme(themeFlag)
			if err != nil {
				presenter.ShowError("Erro ao salvar o tema.", err)
			}
			presenter.ShowSuccess(fmt.Sprintf("Tema '%s' aplicado com sucesso!", themeFlag))
		}
		return
	}

	// Se nenhum command ou flag for especificado, mostre a ajuda.
	presenter.ShowHelp(cmd)
}
