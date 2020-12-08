# Disable echoing of commands
MAKEFLAGS += --silent

.PHONY: build run lint format package clean

# Add the Info.plist file to the binary
LINKER_FLAGS=-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ./Info.plist

source := $(shell find Sources -type f -name "*.swift")
version := $(shell grep 'CFBundleShortVersionString' -A1 Info.plist | tail -1 | sed 's/.*<string>\([^<]\+\)<\/string>.*/\1/')

build: build/release/QuickTerm

build/release/QuickTerm: $(source)
	swift build --configuration release $(LINKER_FLAGS) --build-path build

run:
	swift run $(LINKER_FLAGS) --build-path build

# Requires swift-format
# brew install swift-format
lint:
	swift-format --mode lint --configuration swift-format.json --recursive .

# Requires swift-format
# brew install swift-format
format:
	swift-format --mode format --configuration swift-format.json --in-place --recursive .

package: distribution/QuickTerm\ v$(version).app.zip distribution/QuickTerm\ v$(version).dmg

build/QuickTerm.app: build/release/QuickTerm Info.plist
	mkdir -p build/QuickTerm.app/Contents/MacOS
	cp build/release/QuickTerm build/QuickTerm.app/Contents/MacOS
	cp Info.plist build/QuickTerm.app/Contents

# Requires NPM and clang
build/QuickTerm\ v$(version).dmg: build/QuickTerm.app
	# create-dmg exits with 2 if everything worked but it wasn't code signed
	# due to no identity being defined
	CXX=clang CC=clang npx create-dmg build/QuickTerm.app build || [[ $$? -eq 2 ]] || exit 1

distribution/QuickTerm\ v$(version).app.zip: build/QuickTerm.app
	mkdir -p distribution
	zip -r "$@" "$<"

distribution/QuickTerm\ v$(version).dmg: build/QuickTerm\ $(version).dmg
	mkdir -p distribution
	cp "$<" "$@"

clean:
	rm -r build distribution &> /dev/null || true
