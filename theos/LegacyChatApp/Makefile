TARGET := iphone:clang:7.1:6.0
ARCHS = armv7 armv7s

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LegacyChatApp

LegacyChatApp_FILES = \
	main.m \
	LCAppDelegate.m \
	LCChatViewController.m \
	LCConversationsViewController.m \
	LCSettingsViewController.m \
	LCSystemPromptViewController.m \
	LCAboutViewController.m \
	LCProviderProfilesViewController.m \
	LCProviderProfileEditorViewController.m \
	LCConversationStore.m \
	CGAPIHelper.m \
	CGAPICommunicator.m \
	CGMessage.m \
	CGConversation.m \
	CGChatTableCell.m \
	CGAuthorTableCell.m \
	TRMalleableFrameView.m \
	NSURLConnection+FoundationCompletions.m

LegacyChatApp_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
LegacyChatApp_CFLAGS = -I../../ChatGPT/Libraries/SSL -I../../ChatGPT/Libraries/SSL/curl
LegacyChatApp_LDFLAGS = \
	../../ChatGPT/Libraries/SSL/libcurl.a \
	../../ChatGPT/Libraries/SSL/libssl.a \
	../../ChatGPT/Libraries/SSL/libcrypto.a \
	../../ChatGPT/Libraries/SSL/libz.a
LegacyChatApp_INFOPLIST = Resources/Info.plist
LegacyChatApp_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
