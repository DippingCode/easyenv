// Package themeloaderservice
package themeloaderservice

import (
	"fmt"
	"os"
	"path/filepath"

	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
	"github.com/charmbracelet/lipgloss"
	"gopkg.in/yaml.v2"
)


type StyleProperties struct {
	Foreground  string `yaml:"foreground"`
	Background  string `yaml:"background"`
	Bold        bool   `yaml:"bold"`
	Underline   bool   `yaml:"underline"`
	Italic      bool   `yaml:"italic"`
	Padding     []int  `yaml:"padding"`
	BorderType  string `yaml:"border_type"`
	BorderColor string `yaml:"border_color"`
}

// ThemeData armazena a definição completa de um tema.
type ThemeData struct {
	PrimaryColor    string `yaml:"primary_color"`
	SecondaryColor  string `yaml:"secondary_color"`
	SuccessColor    string `yaml:"success_color"`
	ErrorColor      string `yaml:"error_color"`
	WarningColor    string `yaml:"warning_color"`
	InfoColor       string `yaml:"info_color"`
	BackgroundColor string `yaml:"background_color"`
	ForegroundColor string `yaml:"foreground_color"`
	HighlightColor  string `yaml:"highlight_color"`

	Styles map[string]StyleProperties `yaml:"styles"`
}

// ThemesConfig armazena as definições de todos os temas.
type ThemesConfig struct {
	Themes map[string]ThemeData `yaml:"themes"`
}

// ThemeLoaderService lida com a lógica de carregar o tema.
type ThemeLoaderService struct {
	userConfigPath string
	themesAssetsPath string // Novo campo para o caminho do asset
}

// NewThemeLoaderService cria um novo serviço de carregamento de temas.
func NewThemeLoaderService(userConfigPath, themesAssetsPath string) *ThemeLoaderService {
	return &ThemeLoaderService{
		userConfigPath: userConfigPath,
		themesAssetsPath: themesAssetsPath,
	}
}

// LoadTheme carrega o tema do usuário, com fallback para o tema padrão.
func (s *ThemeLoaderService) LoadTheme() (themetemplate.ThemeTemplate, error) {
	// Passo 1: Ler a preferência do usuário.
	var userPrefs struct {
		Theme string `yaml:"theme"`
	}
	userConfigData, err := os.ReadFile(s.userConfigPath)
	if err == nil {
		yaml.Unmarshal(userConfigData, &userPrefs)
	}

	// Passo 2: Definir qual arquivo de tema carregar.
	themeToLoad := "dark" // Tema padrão
	if userPrefs.Theme != "" {
		themeToLoad = userPrefs.Theme
	}

	// Tentar carregar o tema de um arquivo customizado.
	themeFilePath := filepath.Join(filepath.Dir(s.userConfigPath), themeToLoad + ".yml")
	themesData, err := os.ReadFile(themeFilePath)
	
	// Se o arquivo customizado não existir, usar o template padrão.
	if err != nil {
		themesData, err = os.ReadFile(s.themesAssetsPath)
		if err != nil {
			return themetemplate.ThemeTemplate{}, fmt.Errorf("erro fatal: o arquivo de temas padrao nao foi encontrado em %s: %w", s.themesAssetsPath, err)
		}
	}
	
	// Passo 3: Decodificar os dados do tema.
	var themesConfig ThemesConfig
	if err := yaml.Unmarshal(themesData, &themesConfig); err != nil {
		return themetemplate.ThemeTemplate{}, fmt.Errorf("erro ao decodificar os temas: %w", err)
	}

	// Passo 4: Retornar o tema solicitado.
	themeData, ok := themesConfig.Themes[themeToLoad]
	if !ok {
		// Se o tema customizado não tiver uma entrada no arquivo, retorna o padrão.
		themeData = themesConfig.Themes["dark"]
	}

	// Passo 5: Construir e retornar a struct final.
	finalTheme := themetemplate.ThemeTemplate{
		PrimaryColor:    lipgloss.Color(themeData.PrimaryColor),
		SecondaryColor:  lipgloss.Color(themeData.SecondaryColor),
		SuccessColor:    lipgloss.Color(themeData.SuccessColor),
		ErrorColor:      lipgloss.Color(themeData.ErrorColor),
		WarningColor:    lipgloss.Color(themeData.WarningColor),
		InfoColor:       lipgloss.Color(themeData.InfoColor),
		BackgroundColor: lipgloss.Color(themeData.BackgroundColor),
		ForegroundColor: lipgloss.Color(themeData.ForegroundColor),
		HighlightColor:  lipgloss.Color(themeData.HighlightColor),
	}
	
	// A lógica para converter as StyleProperties para lipgloss.Style viria aqui.
	
	return finalTheme, nil
}