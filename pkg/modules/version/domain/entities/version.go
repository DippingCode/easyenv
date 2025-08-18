package entities

// Version represents the application version information.
type Version struct {
	Title  string // e.g., "v0.0.2 - 2025-08-17"
	Number string // e.g., "0.0.2"
	Date   string // e.g., "2025-08-17"
	Meta   VersionMeta
}

// VersionMeta holds metadata about the version.
type VersionMeta struct {
	Added     []string
	Changed   []string
	Notes     []string
	NextSteps []string
	Build     BuildDetails
}

// BuildDetails holds build-specific information.
type BuildDetails struct {
	Build  string
	Tag    string
	Commit string
}