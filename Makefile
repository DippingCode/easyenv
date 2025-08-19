GOPATH := $(shell go env GOPATH)

fmt:
	$(GOPATH)/bin/gofumpt -l -w .
	$(GOPATH)/bin/gci write -s standard -s default -s prefix\(github.com/DippingCode/easyenv\) .

lint:
	$(GOPATH)/bin/golangci-lint run

test:
	go test ./... -race -cover

ci: fmt lint test
