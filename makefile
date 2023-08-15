# Arquivo Go
GO_FILE := main.go

GOPATH := $(shell go env GOPATH)

deploy:
	cd ./cmd && env GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -o ../bin/login/main ./login/$(GO_FILE)
	cd ./cmd && env GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -o ../bin/authorize/main ./authorize/$(GO_FILE)
	zip -j ./bin/login/login.zip ./bin/login/main
	zip -j ./bin/authorize/authorize.zip ./bin/authorize/main
	cd ./terraform && terraform apply --auto-approve
