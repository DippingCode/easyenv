// Package entities contém objetos de transferência de dados (transacionais) entre camadas da feature version.
package entities

// Version representa a versão da aplicação.
// Mantém os campos básicos já existentes (Number/Build/Badge) e adiciona Title e um meta mais rico.
type Version struct {
	Number string      `json:"number"`           // ex.: "0.0.2"
	Date   string
	Build  string      `json:"build,omitempty"`  // ex.: "25" (mantido por compatibilidade)
	Badge  string      `json:"badge,omitempty"`  // ex.: "alpha", "beta", "rc"
	Title  string      `json:"title,omitempty"`  // ex.: "[0.0.2] - 2025-08-17"
	Meta   VersionMeta `json:"meta"`             // detalhes estruturados da versão
}

// BuildDetails representa informações de build/tag/commit associadas à versão.
type BuildDetails struct {
	Build  string `json:"build,omitempty"`  // ex.: "25"
	Tag    string `json:"tag,omitempty"`    // ex.: "v0.0.2+25"
	Commit string `json:"commit,omitempty"` // ex.: "feat(version): ..."
}

// VersionMeta contém informações adicionais (Added/Changed/Notes/NextSteps) e dados de build.
type VersionMeta struct {
	Added       []string     `json:"added,omitempty"`        // seção "Added" do CHANGELOG
	Changed     []string     `json:"changed,omitempty"`      // seção "Changed" do CHANGELOG
	Notes       []string     `json:"notes,omitempty"`        // seção "Notes" do CHANGELOG
	NextSteps   []string     `json:"next_steps,omitempty"`   // seção "Next Steps" do CHANGELOG
	Build       BuildDetails `json:"build_details,omitempty"`// seção "Build Details" do CHANGELOG
}