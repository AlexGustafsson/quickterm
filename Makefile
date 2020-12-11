# Disable echoing of commands
MAKEFLAGS += --silent

.PHONY: build run lint format package clean sign

modules=QuickTerm QuickTermBroker
sharedModules=QuickTermShared

sourceToLint := $(shell find Sources -type f -name "*.swift")
# TODO: add support for multiple shared modules
sharedSource := $(shell find Sources/$(sharedModules) -type f -name "*.swift")

version := $(shell grep 'CFBundleShortVersionString' -A1 SupportingFiles/QuickTerm/Info.plist | tail -1 | sed 's/.*<string>\([^<]\+\)<\/string>.*/\1/')

build: build/QuickTerm.app

# Macro to create a rule to build a module
define buildModule
build/$(1)/release/$(1): $(shell find "Sources/$(1)" -type f -name "*.swift") $(sharedSource) SupportingFiles/$(1)/Info.plist
	swift build --configuration release --product "$(1)" --build-path "build/$(1)"
endef

# Create the build rule for all modules
$(foreach module,$(modules),\
	$(eval $(call buildModule,$(module))))

run: build/QuickTerm.app
ifndef args
	open build/QuickTerm.app
else
	./build/QuickTerm.app/Contents/MacOS/QuickTerm $(args)
endif


# Requires swift-format
# brew install swift-format
lint:
	swift-format --mode lint --configuration swift-format.json --recursive .

# Requires swift-format
# brew install swift-format
format:
	swift-format --mode format --configuration swift-format.json --in-place --recursive .

package: distribution/QuickTerm\ v$(version).app.zip distribution/QuickTerm\ v$(version).dmg

build/QuickTermBroker.xpc: build/QuickTermBroker/release/QuickTermBroker SupportingFiles/QuickTermBroker/Info.plist
	mkdir -p build/QuickTermBroker.xpc/Contents/MacOS
	cp build/QuickTermBroker/release/QuickTermBroker build/QuickTermBroker.xpc/Contents/MacOS
	cp SupportingFiles/QuickTermBroker/Info.plist build/QuickTermBroker.xpc/Contents

build/QuickTerm.app: build/QuickTerm/release/QuickTerm SupportingFiles/QuickTerm/Info.plist build/QuickTermBroker.xpc
	mkdir -p build/QuickTerm.app/Contents/MacOS
	mkdir -p build/QuickTerm.app/Contents/XPCServices
	cp build/QuickTerm/release/QuickTerm build/QuickTerm.app/Contents/MacOS
	cp SupportingFiles/QuickTerm/Info.plist build/QuickTerm.app/Contents
	cp -r build/QuickTermBroker.xpc build/QuickTerm.app/Contents/XPCServices

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

sign: build/QuickTerm.app
	# Use security find-identity -v -p codesigning to find available certificates
	codesign -o runtime --force --entitlements SupportingFiles/QuickTermBroker/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app/Contents/XPCServices/QuickTermBroker.xpc/Contents/MacOS/QuickTermBroker
	codesign -o runtime --force --entitlements SupportingFiles/QuickTermBroker/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app/Contents/XPCServices/QuickTermBroker.xpc
	codesign -o runtime --force --entitlements SupportingFiles/QuickTerm/Entitlements.plist --sign "$(CODESIGN_IDENTITY)" --timestamp build/QuickTerm.app

logs:
	# TODO: AppleScript to open logs with following filteR
	# process:QuickTerm
  # kategori:main
  # kategori:broker

clean:
	rm -rf build distribution &> /dev/null || true
