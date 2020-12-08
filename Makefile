# Disable echoing of commands
MAKEFLAGS += --silent

.PHONY: build run lint format package clean

# Add the Info.plist file to the binary
LINKER_FLAGS=-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ./Info.plist

source := $(shell find Sources -type f -name "*.swift")

build: build/release/QuickTerm

build/release/QuickTerm: $(source)
	swift build --configuration release $(LINKER_FLAGS) --build-path build

run:
	swift run $(LINKER_FLAGS) --build-path build

# brew install swift-format
lint:
	swift-format --mode lint --configuration swift-format.json --recursive .

# brew install swift-format
format:
	swift-format --mode format --configuration swift-format.json --in-place --recursive .

package: build/QuickTerm.app

build/QuickTerm.app: build/release/QuickTerm Info.plist
	mkdir -p build/QuickTerm.app
	cp build/release/QuickTerm build/QuickTerm.app
	cp Info.plist build/QuickTerm.app

clean:
	rm -r build &> /dev/null || true
