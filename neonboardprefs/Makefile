ARCHS = arm64
include $(THEOS)/makefiles/common.mk
TARGET := iphone:clang:8.1

BUNDLE_NAME = neonboardprefs
neonboardprefs_FILES = NBPRootListController.m ThemeListViewController.m ThemeSortViewController.m
neonboardprefs_INSTALL_PATH = /Library/PreferenceBundles
neonboardprefs_FRAMEWORKS = UIKit
neonboardprefs_PRIVATE_FRAMEWORKS = Preferences
neonboardprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/neonboardprefs.plist$(ECHO_END)
