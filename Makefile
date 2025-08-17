.PHONY: tidy run build
tidy:
	go mod tidy

run: tidy
	go run ./src

build: tidy
	go build -o bin/easyenv ./src