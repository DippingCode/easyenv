package utils

import (
	"encoding/json"
	"io/ioutil"
)

// ReadMarkdownFile reads a markdown file and returns its content as a JSON string.
func ReadMarkdownFile(filePath string) (string, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", err
	}

	content := map[string]string{"content": string(data)}
	jsonContent, err := json.Marshal(content)
	if err != nil {
		return "", err
	}

	return string(jsonContent), nil
}
