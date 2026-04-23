#import "LCSystemPromptViewController.h"
#import "CGAPIHelper.h"

@interface LCSystemPromptViewController ()

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIButton *defaultButton;
@property (nonatomic, retain) UILabel *footerLabel;

@end

@implementation LCSystemPromptViewController

@synthesize textView = _textView;
@synthesize defaultButton = _defaultButton;
@synthesize footerLabel = _footerLabel;

- (id)init {
	self = [super init];
	if (self) {
		self.title = @"System Prompt";
	}
	return self;
}

- (void)loadView {
	[super loadView];
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.view.backgroundColor = [UIColor colorWithWhite:0.93f alpha:1.0f];

	UITextView *textView = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
	textView.font = [UIFont systemFontOfSize:15.0f];
	textView.textColor = [UIColor colorWithWhite:0.18f alpha:1.0f];
	textView.backgroundColor = [UIColor whiteColor];
	textView.delegate = self;
	textView.text = [CGAPIHelper configuredSystemPrompt];
	self.textView = textView;
	[self.view addSubview:self.textView];

	UIButton *defaultButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[defaultButton setTitle:@"Restore Default" forState:UIControlStateNormal];
	[defaultButton addTarget:self action:@selector(defaultTapped) forControlEvents:UIControlEventTouchUpInside];
	self.defaultButton = defaultButton;
	[self.view addSubview:self.defaultButton];

	UILabel *footerLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	footerLabel.backgroundColor = [UIColor clearColor];
	footerLabel.font = [UIFont systemFontOfSize:13.0f];
	footerLabel.textColor = [UIColor colorWithWhite:0.42f alpha:1.0f];
	footerLabel.numberOfLines = 0;
	footerLabel.textAlignment = NSTextAlignmentCenter;
	footerLabel.text = @"This prompt is sent before each request, but is not saved into chat history. Clear it to disable.";
	self.footerLabel = footerLabel;
	[self.view addSubview:self.footerLabel];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)] autorelease];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGRect bounds = self.view.bounds;
	CGFloat horizontalInset = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 24.0f : 12.0f);
	CGFloat contentWidth = bounds.size.width - (horizontalInset * 2.0f);
	self.textView.frame = CGRectMake(horizontalInset, 14.0f, contentWidth, bounds.size.height - 150.0f);
	self.defaultButton.frame = CGRectMake(horizontalInset, CGRectGetMaxY(self.textView.frame) + 10.0f, contentWidth, 34.0f);
	self.footerLabel.frame = CGRectMake(horizontalInset + 8.0f, CGRectGetMaxY(self.defaultButton.frame) + 8.0f, contentWidth - 16.0f, 58.0f);
}

- (void)saveTapped {
	[CGAPIHelper saveSystemPrompt:self.textView.text];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)defaultTapped {
	self.textView.text = [CGAPIHelper defaultSystemPrompt];
}

- (void)dealloc {
	[_textView release];
	[_defaultButton release];
	[_footerLabel release];
	[super dealloc];
}

@end
