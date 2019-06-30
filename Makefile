#DEBUG=0
#FINALPACKAGE=1
THEOS_DEVICE_IP = 192.168.0.87
ARCHS = arm64 arm64e armv7
TARGET := iphone:clang:12.0:7.0
include /Users/tanayfindley/theos/makefiles/common.mk

TWEAK_NAME = NeonBoard
NeonBoard_FILES = Tweak.xm Calendar.xm UIColor+HTMLColors.mm
NeonBoard_FRAMEWORKS = UIKit QuartzCore CoreGraphics
NeonBoard_PRIVATE_FRAMEWORKS = MobileIcons
Tweak.xm_CFLAGS = -fobjc-arc
Calendar.xm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += neonboardprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
