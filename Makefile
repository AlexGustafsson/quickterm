.PHONY: build run

LINKER_FLAGS=-Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ./Info.plist

build:
	swift build --configuration release $(LINKER_FLAGS)

run:
	swift run $(LINKER_FLAGS)

clean:
	rm -r .build
