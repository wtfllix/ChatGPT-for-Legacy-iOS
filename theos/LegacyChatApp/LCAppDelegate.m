#import "LCAppDelegate.h"
#import "CGAPIHelper.h"
#import "LCChatViewController.h"

@implementation LCAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[CGAPIHelper registerProviderDefaults];

	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

	LCChatViewController *rootViewController = [[[LCChatViewController alloc] init] autorelease];
	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
	if ([navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
		[navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"Images/bar-BG.png"] forBarMetrics:UIBarMetricsDefault];
	}
	if ([navigationController.navigationBar respondsToSelector:@selector(setTitleTextAttributes:)]) {
		NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor colorWithWhite:0.18f alpha:1.0f], UITextAttributeTextColor,
			[UIColor colorWithWhite:1.0f alpha:0.75f], UITextAttributeTextShadowColor,
			[NSValue valueWithUIOffset:UIOffsetMake(0.0f, 1.0f)], UITextAttributeTextShadowOffset,
			[UIFont boldSystemFontOfSize:20.0f], UITextAttributeFont,
			nil];
		[navigationController.navigationBar setTitleTextAttributes:titleAttributes];
	}

	self.window.rootViewController = navigationController;
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)dealloc {
	[_window release];
	[super dealloc];
}

@end
