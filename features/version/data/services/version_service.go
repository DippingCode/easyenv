// Package services contém serviços de infraestrutura da feature version.
// Responsável por buscar dados em fontes externas (arquivos, rede, etc).
package services

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/DippingCode/easyenv/features/version/domain/entities"
)

// VersionService provê os dados da versão atual.
type VersionService struct{}

// NewVersionService cria uma nova instância do serviço.
func NewVersionService() *VersionService {
	return &VersionService{}
}

// GetVersion é o ponto de entrada do domínio.
func (s *VersionService) GetVersion() (*entities.Version, error) {
	return s.FetchVersion()
}

// FetchVersion lê o CHANGELOG.md, localiza a primeira versão e a parseia.
func (s *VersionService) FetchVersion() (*entities.Version, error) {
	changelogPath, err := resolveChangelogPath()
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(changelogPath)
	if err != nil {
		return nil, fmt.Errorf("falha ao ler %s: %w", changelogPath, err)
	}
	md := string(data)

	sectionBody, headerLine, err := firstVersionSection(md)
	if err != nil {
		return nil, err
	}

	number, date := parseHeader(headerLine)

	added := extractList(sectionBody, "Added")
	changed := extractList(sectionBody, "Changed")
	notes := extractList(sectionBody, "Notes")
	next := extractList(sectionBody, "Next Steps")
	bd := extractBuildDetails(sectionBody)

	v := &entities.Version{
		Title:     strings.TrimSpace(headerLine),
		Number:    number,
		Date: date,
		Meta: entities.VersionMeta{
			Added: added,
			Changed: changed,
			Notes: notes,
			NextSteps: next,
			Build: entities.BuildDetails{
				Build:  bd.Build,
				Tag:    bd.Tag,
				Commit: bd.Commit,
			},
		},
	}
	return v, nil
}

// resolveChangelogPath tenta localizar o CHANGELOG.md na raiz do projeto.
func resolveChangelogPath() (string, error) {
	cw, _ := os.Getwd()
	candidates := []string{
		filepath.Join(cw, "CHANGELOG.md"),
		filepath.Join(cw, "docs", "CHANGELOG.md"),
	}

	for _, p := range candidates {
		if st, err := os.Stat(p); err == nil && !st.IsDir() {
			return p, nil
		}
	}
	return "", errors.New("CHANGELOG.md não encontrado (tente na raiz do projeto)")
}

// firstVersionSection encontra a primeira seção de versão (após "## Versions" se existir).
func firstVersionSection(md string) (sectionBody string, headerLine string, err error) {
	// Tenta ancorar em "## Versions" (ou "## Version")
	anchorRE := regexp.MustCompile(`(?mi)^##\s*Versions?\s*$`)
	start := 0
	if loc := anchorRE.FindStringIndex(md); loc != nil {
		start = loc[1]
	}

	// Cabeçalho de versão: "#### [0.0.2] - 2025-08-17"
	verHeaderRE := regexp.MustCompile(`(?m)^#{3,6}\s*$begin:math:display$(\\d+\\.\\d+\\.\\d+)$end:math:display$\s*-\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$`)

	sub := md[start:]
	if m := verHeaderRE.FindStringIndex(sub); m != nil {
		headerLine = strings.TrimSpace(sub[m[0]:m[1]])
		// corpo vai até próximo cabeçalho de versão ou fim
		rest := sub[m[1]:]
		if n := verHeaderRE.FindStringIndex(rest); n != nil {
			sectionBody = rest[:n[0]]
		} else {
			sectionBody = rest
		}
		return sectionBody, headerLine, nil
	}

	// Fallback: procura no arquivo inteiro
	if m := verHeaderRE.FindStringIndex(md); m != nil {
		headerLine = strings.TrimSpace(md[m[0]:m[1]])
		rest := md[m[1]:]
		if n := verHeaderRE.FindStringIndex(rest); n != nil {
			sectionBody = rest[:n[0]]
		} else {
			sectionBody = rest
		}
		return sectionBody, headerLine, nil
	}

	return "", "", errors.New("não foi possível localizar a primeira versão no CHANGELOG.md")
}

// parseHeader extrai número e data do cabeçalho da versão.
func parseHeader(headerLine string) (number string, date string) {
	re := regexp.MustCompile(`^\s*#{3,6}\s*$begin:math:display$([0-9]+\\.[0-9]+\\.[0-9]+)$end:math:display$\s*-\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$`)
	if m := re.FindStringSubmatch(headerLine); m != nil {
		return m[1], m[2]
	}
	return "", ""
}

// extractList captura bullets após um heading (ex.: "###### Added") até o próximo heading.
func extractList(body string, heading string) []string {
	// Encontra o heading da seção
	secRE := regexp.MustCompile(`(?mi)^#{3,6}\s*` + regexp.QuoteMeta(heading) + `\s*$`)
	loc := secRE.FindStringIndex(body)
	if loc == nil {
		return nil
	}

	// Daqui até próximo heading (ou fim)
	rest := body[loc[1]:]
	stopRE := regexp.MustCompile(`(?m)^#{3,6}\s*(?:[A-Za-z].*|$begin:math:display$[0-9]+\\.[0-9]+\\.[0-9]+$end:math:display$)\s*$`)
	if stop := stopRE.FindStringIndex(rest); stop != nil {
		rest = rest[:stop[0]]
	}

	// Bullets: "-", "*" ou "•"
	bulletRE := regexp.MustCompile(`(?m)^\s*[-*•]\s*(.+?)\s*$`)
	var out []string
	for _, m := range bulletRE.FindAllStringSubmatch(rest, -1) {
		item := strings.TrimSpace(m[1])
		if item != "" {
			out = append(out, item)
		}
	}
	return out
}

// buildTriplet guarda Build/Tag/Commit temporariamente.
type buildTriplet struct {
	Build  string
	Tag    string
	Commit string
}

// extractBuildDetails busca linhas (com ou sem bullet) de Build/Tag/Commit.
func extractBuildDetails(body string) buildTriplet {
	// Aceita com bullet (-/*/•) ou sem bullet
	re := func(label string) *regexp.Regexp {
		return regexp.MustCompile(`(?mi)^\s*(?:[-*•]\s*)?` + regexp.QuoteMeta(label) + `\s*:\s*(.+?)\s*$`)
	}

	var bd buildTriplet
	if m := re("Build").FindStringSubmatch(body); m != nil {
		bd.Build = strings.TrimSpace(m[1])
	}
	if m := re("Tag").FindStringSubmatch(body); m != nil {
		bd.Tag = strings.TrimSpace(m[1])
	}
	if m := re("Commit").FindStringSubmatch(body); m != nil {
		bd.Commit = strings.TrimSpace(m[1])
	}
	return bd
}