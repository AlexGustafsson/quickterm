# Disable echoing of commands
MAKEFLAGS += --silent

.PHONY: build run

LINKER_FLAGS=-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ./Info.plist

build:
	swift build --configuration release -O $(LINKER_FLAGS)

run:
	swift run $(LINKER_FLAGS)

# brew install swift-format
lint:
	swift-format --mode lint --configuration swift-format.json --recursive .

# brew install swift-format
format:
	swift-format --mode format --configuration swift-format.json --in-place --recursive .

package: build
	mkdir -p build/dist
	mkdir build/QuickTerm.app
	cp .build/release/QuickTerm build/QuickTerm.app
	cp Info.plist build/QuickTerm.app

clean:
	rm -r .build
