all: githash
	cd cmd/jcp; go install
	cd cmd/jsrv; go install

githash:
	/bin/echo "package jsync" > jsync/gitcommit.go
	/bin/echo "func init() { LAST_GIT_COMMIT_HASH = \"$(shell git rev-parse HEAD)\"; NEAREST_GIT_TAG= \"$(shell git describe --abbrev=0 --tags)\"; GIT_BRANCH=\"$(shell git rev-parse --abbrev-ref  HEAD)\"; GO_VERSION=\"$(shell go version)\";}" >> jsync/gitcommit.go

