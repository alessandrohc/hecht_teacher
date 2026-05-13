APP_NAME       := HechtTeacher
DISPLAY_NAME   := Hecht Teacher
BUNDLE_ID      := com.hecht.teacher
BUILD_DIR      := build
APP_BUNDLE     := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS       := $(APP_BUNDLE)/Contents
MACOS_DIR      := $(CONTENTS)/MacOS
RES_DIR        := $(CONTENTS)/Resources
INSTALL_DIR    := $(HOME)/Applications

.PHONY: all build bundle install clean run reregister icon

all: bundle

build:
	swift build -c release

icon: Resources/AppIcon.icns

Resources/AppIcon.icns: Tools/MakeIcon.swift
	@echo "→ Generating app icon"
	@swift Tools/MakeIcon.swift
	@iconutil -c icns -o Resources/AppIcon.icns Tools/AppIcon.iconset
	@echo "✓ Wrote Resources/AppIcon.icns"

bundle: build icon
	@echo "→ Creating $(APP_BUNDLE)"
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(MACOS_DIR)" "$(RES_DIR)"
	@cp ".build/release/$(APP_NAME)" "$(MACOS_DIR)/$(APP_NAME)"
	@cp "Resources/Info.plist" "$(CONTENTS)/Info.plist"
	@cp "Resources/AppIcon.icns" "$(RES_DIR)/AppIcon.icns"
	@/usr/bin/codesign --force --deep --sign - "$(APP_BUNDLE)" 2>/dev/null || true
	@echo "✓ Built $(APP_BUNDLE)"

install: bundle
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
		-f "$(INSTALL_DIR)/$(APP_NAME).app" >/dev/null 2>&1 || true
	@/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
	@echo "✓ Installed at $(INSTALL_DIR)/$(APP_NAME).app"
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
