# Disable echoing of commands
MAKEFLAGS += --silent

# Always use clang, no matter if GCC is configured
CXX=clang
CPP=clang
CC=clang

.PHONY: build run setup setup-git-hooks test lint format package sign logs help clean

modules=QuickTerm QuickTermBroker
sharedModules=QuickTermShared QuickTermLibrary

sharedSource := $(shell echo $(sharedModules) | tr ' ' '\n' | while read line; do find "Sources/$$line" -type f -iname '*.swift'; done)

version := $(shell grep 'CFBundleShortVersionString' -A1 SupportingFiles/QuickTerm/Info.plist | tail -1 | sed 's/.*<string>\([^<]\+\)<\/string>.*/\1/')

# Produce a short description of available make commands
help:
	pcregrep -Mo '^(#.*\n)+^[^# ]+:' Makefile | sed "s/^\([^# ]\+\):/> \1/g" | sed "s/^#\s\+\(.\+\)/\1/g" | GREP_COLORS='ms=1;34' grep -E --color=always '^>.*|$$' | GREP_COLORS='ms=1;37' grep -E --color=always '^[^>].*|$$'

# Build the application
build: build/QuickTerm.app

# Macro to create a rule to build a module
define buildModule
build/$(1)/release/$(1): $(shell find "Sources/$(1)" -type f -name "*.swift") $(sharedSource) SupportingFiles/$(1)/Info.plist
	swift build --configuration release --product "$(1)" --build-path "build/$(1)"
endef

# Create the build rule for all modules
$(foreach module,$(modules),\
	$(eval $(call buildModule,$(module))))

# Run the application
# To supply arguments use make run args="argument1 argument2 ..."
run: build/QuickTerm.app
ifndef args
	kill -9 "$$(ps aux | grep "$(shell pwd)/build/QuickTerm.app/Contents/MacOS/QuickTerm$$" | tail -1 | awk '{print $$2}')" &> /dev/null || true
	open build/QuickTerm.app
else
	./build/QuickTerm.app/Contents/MacOS/QuickTerm $(args)
endif

# Run all tests
test:
	swift test --build-path "build/test"

# Setup the project for development
setup: setup-git-hooks

# Install the recommended git hooks
setup-git-hooks: .githooks/pre-commit
	cp .githooks/* .git/hooks

# Lint all Swift code
# Requires swiftformat: brew install swiftformat
lint:
	swiftformat --lint --verbose --config .swiftformat .

# Format all Swift code
# Requires swiftformat: brew install swiftformat
format:
	swiftformat --config .swiftformat .

# Package the application, ready for distribution. Does not sign the binaries.
# To package signed binaries run "make build sign package" instead
package: distribution/QuickTerm\ v$(version).app.zip distribution/QuickTerm\ v$(version).dmg

build/QuickTermBroker.xpc: build/QuickTermBroker/release/QuickTermBroker SupportingFiles/QuickTermBroker/Info.plist
	mkdir -p build/QuickTermBroker.xpc/Contents/MacOS
	cp build/QuickTermBroker/release/QuickTermBroker build/QuickTermBroker.xpc/Contents/MacOS
	cp SupportingFiles/QuickTermBroker/Info.plist build/QuickTermBroker.xpc/Contents

build/QuickTerm.app: build/QuickTerm/release/QuickTerm SupportingFiles/QuickTerm/Info.plist build/QuickTermBroker.xpc build/AppIcon.icns
	mkdir -p build/QuickTerm.app/Contents/MacOS
	mkdir -p build/QuickTerm.app/Contents/XPCServices
	cp build/QuickTerm/release/QuickTerm build/QuickTerm.app/Contents/MacOS
	cp SupportingFiles/QuickTerm/Info.plist build/QuickTerm.app/Contents
	cp -r build/QuickTermBroker.xpc build/QuickTerm.app/Contents/XPCServices
	cp -r SupportingFiles/QuickTerm/Resources build/QuickTerm.app/Contents/Resources
	cp build/AppIcon.icns build/QuickTerm.app/Contents/Resources/AppIcon.icns

build/AppIcon.icns: SupportingFiles/QuickTerm/icon.png
	rm -r ./build/AppIcon.iconset ./build/AppIcon.icns &>/dev/null || true
	mkdir -p ./build/AppIcon.iconset
	# Create icons for different sizes
	sips -z 16 16 $< --out "./build/AppIcon.iconset/icon_16x16.png"
	sips -z 32 32 $< --out "./build/AppIcon.iconset/icon_16x16@2x.png"
	sips -z 32 32 $< --out "./build/AppIcon.iconset/icon_32x32.png"
	sips -z 64 64 $< --out "./build/AppIcon.iconset/icon_32x32@2x.png"
	sips -z 128 128 $< --out "./build/AppIcon.iconset/icon_128x128.png"
	sips -z 256 256 $< --out "./build/AppIcon.iconset/icon_128x128@2x.png"
	sips -z 256 256 $< --out "./build/AppIcon.iconset/icon_256x256.png"
	sips -z 512 512 $< --out "./build/AppIcon.iconset/icon_256x256@2x.png"
	sips -z 512 512 $< --out "./build/AppIcon.iconset/icon_512x512.png"
	# Compile icons
	iconutil --convert icns --output ./build/AppIcon.icns ./build/AppIcon.iconset

# Requires NPM and clang
build/QuickTerm\ $(version).dmg: build/QuickTerm.app
	# create-dmg exits with 2 if everything worked but it wasn't code signed
	# due to no identity being defined
	CXX=clang CC=clang npx create-dmg --identity="$(CODESIGN_IDENTITY)" build/QuickTerm.app build || [[ $$? -eq 2 ]] || exit 1

distribution/QuickTerm\ v$(version).app.zip: build/QuickTerm.app
	mkdir -p distribution
	zip -r "$@" "$<"

distribution/QuickTerm\ v$(version).dmg: build/QuickTerm\ $(version).dmg
	mkdir -p distribution
	cp "$<" "$@"

# Sign the built application
# Use "security find-identity -v -p codesigning" to find available certificates.
# Specify your identity in CODESIGN_IDENTITY
sign: build/QuickTerm.app
	codesign -o runtime --force --entitlements SupportingFiles/QuickTermBroker/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app/Contents/XPCServices/QuickTermBroker.xpc/Contents/MacOS/QuickTermBroker
	codesign -o runtime --force --entitlements SupportingFiles/QuickTermBroker/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app/Contents/XPCServices/QuickTermBroker.xpc
	codesign -o runtime --force --entitlements SupportingFiles/QuickTerm/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app

# Tail logs produced by QuickTerm
logs:
	log stream --info --debug --predicate 'subsystem BEGINSWITH "se.axgn.QuickTerm"'

# Remove all dynamically created files
clean:
	rm -rf build distribution &> /dev/null || true
