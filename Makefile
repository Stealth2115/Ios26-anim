TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

# RootHide / Dopamine rootless tweaks
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iOS26Anim

iOS26Anim_FILES = Tweak.x
iOS26Anim_CFLAGS = -fobjc-arc
iOS26Anim_FRAMEWORKS = UIKit QuartzCore CoreGraphics
iOS26Anim_PRIVATE_FRAMEWORKS = BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
