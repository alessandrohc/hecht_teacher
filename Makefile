APP_NAME       := HechtTeacher
DISPLAY_NAME   := Me Write Good
BUNDLE_ID      := com.hecht.teacher
BUILD_DIR      := build
APP_BUNDLE     := $(BUILD_DIR)/$(DISPLAY_NAME).app
LEGACY_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS       := $(APP_BUNDLE)/Contents
MACOS_DIR      := $(CONTENTS)/MacOS
RES_DIR        := $(CONTENTS)/Resources
INSTALL_DIR    := $(HOME)/Applications
INSTALLED_APP  := $(INSTALL_DIR)/$(DISPLAY_NAME).app
LEGACY_INSTALL := $(INSTALL_DIR)/$(APP_NAME).app

.PHONY: all build bundle install clean run reregister icon

all: bundle

build:
	swift build -c release

ICON_SOURCE    := Tools/source_icon.png
ICONSET_DIR    := Tools/AppIcon.iconset

icon: Resources/AppIcon.icns

Resources/AppIcon.icns: $(ICON_SOURCE)
	@echo "→ Generating iconset from $(ICON_SOURCE)"
	@rm -rf "$(ICONSET_DIR)"
	@mkdir -p "$(ICONSET_DIR)"
	@sips -z 16   16   "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_16x16.png"      > /dev/null
	@sips -z 32   32   "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_16x16@2x.png"   > /dev/null
	@sips -z 32   32   "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_32x32.png"      > /dev/null
	@sips -z 64   64   "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_32x32@2x.png"   > /dev/null
	@sips -z 128  128  "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_128x128.png"    > /dev/null
	@sips -z 256  256  "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_128x128@2x.png" > /dev/null
	@sips -z 256  256  "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_256x256.png"    > /dev/null
	@sips -z 512  512  "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_256x256@2x.png" > /dev/null
	@sips -z 512  512  "$(ICON_SOURCE)" --out "$(ICONSET_DIR)/icon_512x512.png"    > /dev/null
	@cp                "$(ICON_SOURCE)"        "$(ICONSET_DIR)/icon_512x512@2x.png"
	@iconutil -c icns -o Resources/AppIcon.icns "$(ICONSET_DIR)"
	@echo "✓ Wrote Resources/AppIcon.icns"

bundle: build icon
	@echo "→ Creating $(APP_BUNDLE)"
	@rm -rf "$(APP_BUNDLE)" "$(LEGACY_BUNDLE)"
	@mkdir -p "$(MACOS_DIR)" "$(RES_DIR)"
	@cp ".build/release/$(APP_NAME)" "$(MACOS_DIR)/$(APP_NAME)"
	@cp "Resources/Info.plist" "$(CONTENTS)/Info.plist"
	@cp "Resources/AppIcon.icns" "$(RES_DIR)/AppIcon.icns"
	@/usr/bin/codesign --force --deep --sign - "$(APP_BUNDLE)" 2>/dev/null || true
	@echo "✓ Built $(APP_BUNDLE)"

install: bundle
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALLED_APP)" "$(LEGACY_INSTALL)"
	@cp -R "$(APP_BUNDLE)" "$(INSTALLED_APP)"
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
		-f "$(INSTALLED_APP)" >/dev/null 2>&1 || true
	@/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
	@echo "✓ Installed at $(INSTALLED_APP)"
	@echo "  Open it once from Finder so macOS picks up the Service entry."

reregister:
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
		-kill -r -domain local -domain system -domain user >/dev/null 2>&1 || true
	@/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
	@echo "✓ Services database re-registered. You may need to log out/in for the keyboard shortcut to appear."

run: bundle
	open "$(APP_BUNDLE)"

clean:
	rm -rf "$(BUILD_DIR)" .build Tools/AppIcon.iconset Resources/AppIcon.icns
