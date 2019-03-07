THEOS_DEVICE_IP = 192.168.0.87
ARCHS = armv7 armv7s arm64
TARGET := iphone:clang:8.1
FINALPACKAGE = 1
DEBUG = 0
include /Users/artikus/theos/makefiles/common.mk

TWEAK_NAME = NeonBoard
NeonBoard_FILES = Tweak.xm
NeonBoard_FRAMEWORKS = UIKit QuartzCore CoreGraphics
NeonBoard_PRIVATE_FRAMEWORKS = AppSupport
NeonBoard_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += neonboardprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
