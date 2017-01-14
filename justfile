##################################################
# constants
version = `sed -En 's/version = "([^"]+)"/\1/p' Cargo.toml`
target = "$PWD/target"

##################################################
# build commands
build: # build app with web=false
	CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo build

build-elm: # build just elm (not rust)
	(cd web-ui; npm run build)
	(cd web-ui/dist; tar -cvf ../../src/api/web-ui.tar *)

build-web: build-elm # build and bundle app with web=true
	CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo build --features "web"

build-all: build build-web # just used for testing that you can build both

##################################################
# unit testing/linting commands
test: # do tests with web=false
	RUST_BACKTRACE=1 CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo test --lib

test-web: # do tests with web=true
	(cd web-ui; elm test)
	RUST_BACKTRACE=1 CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo test --lib --features "web"

test-all: test test-web # test all build configurations

filter PATTERN: # run only specific tests
	RUST_BACKTRACE=1 CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo test --lib {{PATTERN}} --features "web"

lint: # run linter
	CARGO_TARGET_DIR={{target}}/nightly rustup run nightly cargo clippy --features "web"
	
test-server: build-elm # run the test-server for e2e testing, still in development
	(CARGO_TARGET_DIR={{target}}/nightly rustup run nightly cargo run --features "web" -- --work-tree web-ui/e2e_tests/ex_proj -v server)

test-e2e: # run e2e tests, still in development
	(cd web-ui; py2t e2e_tests/basic.py)

##################################################
# running commands

api: # run the api server (without the web-ui)
	CARGO_TARGET_DIR={{target}}/stable rustup run stable cargo run -- -v server

frontend: build-elm  # run the full frontend
	CARGO_TARGET_DIR={{target}}/nightly rustup run nightly cargo run --features "web" -- -v server

self-check: # build self and run `rst check` using own binary
	CARGO_TARGET_DIR={{target}}/nightly rustup run nightly cargo run -- check

##################################################
# release command

check: # check the requirements using pre-compiled binary installed on PATH
	rst check

git-verify: # make sure git is clean and on master
	git branch | grep '* master'
	git diff --no-ext-diff --quiet --exit-code

publish: git-verify lint test-all build-all check # publish to github and crates.io
	git commit -a -m "v{{version}} release"
	just publish-fast

publish-fast: # publish without verification
	cargo publish --no-verify
	git push origin master
	git tag -a "v{{version}}" -m "v{{version}}"
	git push origin --tags


##################################################
# developer installation helpers

update: # update rust (stable and nightly)
	rustup update
	rustup run nightly cargo install clippy -f

install-nightly:
	rustup install nightly
