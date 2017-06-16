# justfile
# see: https://github.com/casey/just

##################################################
# constants
version = `sed -En 's/version = "([^"]+)"/\1/p' Cargo.toml | head -n1`
target = "$PWD/target"
target_nightly = target + "/nightly"
target_nightly_app = target_nightly + "/debug/art"
nightly = "CARGO_TARGET_DIR=" + target_nightly + " CARGO_INCREMENTAL=1 rustup run nightly"
export_nightly = "export TARGET_BIN=" + target_nightly_app + " && "

echo TEST='justfile':
	@echo "This is a {{TEST}}"

echo-version:
	echo {{version}}

doc:
	cargo doc --open


##################################################
# build commands

build:
	just web-ui/build-full
	{{nightly}} cargo build --features server
	@echo "built binary to: {{target_nightly_app}}"

# current "release" build includes only exporting static html
build-static: 
	just web-ui/build-static
	just build


##################################################
# unit testing/linting commands
test TESTS="":
	@just web-ui/test
	{{nightly}} cargo test --lib --features server {{TESTS}}

lint: # run linter
	CARGO_TARGET_DIR={{target}}/nightly rustup run nightly cargo clippy --features server
	
test-server-only:
	{{nightly}} cargo test --lib --features server

test-server: # run the test-server for e2e testing, still in development
	just test-server-only

test-e2e: # run e2e tests, still in development
	just build
	{{export_nightly}} py.test2 web-ui/e2e_tests/basic.py -sx


##################################################
# running commands

# run with `just run -- {{args}}`
run ARGS="": # run the api server (without the web-ui)
	{{nightly}} cargo run -- -v {{ARGS}}

serve-rust: 
	{{nightly}} cargo run --features server -- -vv serve

serve-e2e:
	just web-ui/build
	{{nightly}} cargo run --features server -- --work-tree web-ui/e2e_tests/ex_proj serve

serve: # run the full frontend
	just web-ui/build
	just serve-rust

self-check: # build self and run `art check` using own binary
	{{nightly}} cargo run -- check


##################################################
# release command

fmt:
	cargo fmt -- --write-mode overwrite  # don't generate *.bk files
	art fmt -w

check-fmt:
	cargo fmt -- --write-mode=diff

check: check-fmt
	art check

git-verify: # make sure git is clean and on master
	git branch | grep '* master'
	git diff --no-ext-diff --quiet --exit-code

publish: # publish to github and crates.io
	just git-verify lint build-static
	just test
	just self-check
	git commit -a -m "v{{version}} release"
	just publish-cargo
	just publish-git

export-site: build-static
	rm -rf _gh-pages/index.html _gh-pages/css
	{{nightly}} cargo run -- export html && mv index.html css _gh-pages

publish-site: export-site
	rm -rf _gh-pages/index.html _gh-pages/css
	{{nightly}} cargo run -- export html && mv index.html css _gh-pages
	(cd _gh-pages; git commit -am 'v{{version}}' && git push origin gh-pages)

publish-cargo: # publish cargo without verification
	cargo publish --no-verify

publish-git: # publish git without verification
	git push origin master
	git tag -a "v{{version}}" -m "v{{version}}"
	git push origin --tags


##################################################
# developer installation helpers

update: # update rust and tools used by this lib
	rustup update
	(cargo install just -f)
	(cargo install rustfmt -f)
	rustup run nightly cargo install clippy -f

install-nightly:
	rustup install nightly
