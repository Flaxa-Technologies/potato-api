.PHONY: all build release deploy clean

all: release

build:
	cargo build

release:
	cargo build --release

deploy: release
	@mkdir -p ../../plugins
	cp -f target/release/libmy_potato_plugin_linux.so ../../plugins/
	@echo "Deployed to ../../plugins/"

clean:
	cargo clean
