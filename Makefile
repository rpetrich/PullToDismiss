LIBRARY_NAME = PullToDismiss
PullToDismiss_FILES = Tweak.x
PullToDismiss_FRAMEWORKS = Foundation UIKit CoreGraphics
PullToDismiss_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

ADDITIONAL_CFLAGS = -std=c99
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include framework/makefiles/common.mk
include framework/makefiles/library.mk
