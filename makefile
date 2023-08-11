# Arquivo Go
GO_FILE := ./main.go

GOPATH := $(shell go env GOPATH)

deploy:
	cd ./lambda && env GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -o ../bin/main $(GO_FILE)
	zip -j ./bin/login.zip ./bin/main
