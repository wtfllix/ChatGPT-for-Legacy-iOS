#import "LCChatViewController.h"
#import "CGAPICommunicator.h"
#import "CGAPIHelper.h"
#import "CGConversation.h"
#import "CGAuthorTableCell.h"
#import "CGChatTableCell.h"
#import "CGMessage.h"
#import "LCConversationsViewController.h"
#import "LCConversationStore.h"
#import "LCSettingsViewController.h"
#import "TRMalleableFrameView.h"
#import <QuartzCore/QuartzCore.h>

@interface LCChatViewController () <LCConversationsViewControllerDelegate>

@property (nonatomic, retain) UITableView *chatTableView;
@property (nonatomic, retain) UIView *navigationTitleView;
@property (nonatomic, retain) UILabel *navigationTitleLabel;
@property (nonatomic, retain) UIActivityIndicatorView *navigationSpinner;
@property (nonatomic, retain) UILabel *modelNameLabel;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UIButton *attachButton;
@property (nonatomic, retain) UIView *inputContainerView;
@property (nonatomic, retain) UIImageView *inputOverlayView;
@property (nonatomic, retain) UITextView *inputField;
@property (nonatomic, retain) UILabel *inputPlaceholderLabel;
@property (nonatomic, retain) UIView *attachmentPreviewContainer;
@property (nonatomic, retain) UIImageView *attachmentPreviewImageView;
@property (nonatomic, retain) UIButton *attachmentRemoveButton;
@property (nonatomic, retain) UILabel *emptyStateLabel;
@property (nonatomic, retain) NSMutableArray *messages;
@property (nonatomic, retain) UIButton *sendButton;
@property (nonatomic, retain) NSString *currentConversationIdentifier;
@property (nonatomic, retain) NSString *currentConversationTitle;
@property (nonatomic, retain) UIImage *selectedInputImage;
@property (nonatomic, assign) CGFloat keyboardOverlapHeight;
@property (nonatomic, assign) BOOL requestInFlight;
@property (nonatomic, retain) CGMessage *pendingStreamingMessage;
@property (nonatomic, assign) BOOL streamingUpdateScheduled;

@end

@implementation LCChatViewController

@synthesize chatTableView = _chatTableView;
@synthesize navigationTitleView = _navigationTitleView;
@synthesize navigationTitleLabel = _navigationTitleLabel;
@synthesize navigationSpinner = _navigationSpinner;
@synthesize modelNameLabel = _modelNameLabel;
@synthesize toolbar = _toolbar;
@synthesize attachButton = _attachButton;
@synthesize inputContainerView = _inputContainerView;
@synthesize inputOverlayView = _inputOverlayView;
@synthesize inputField = _inputField;
@synthesize inputPlaceholderLabel = _inputPlaceholderLabel;
@synthesize attachmentPreviewContainer = _attachmentPreviewContainer;
@synthesize attachmentPreviewImageView = _attachmentPreviewImageView;
@synthesize attachmentRemoveButton = _attachmentRemoveButton;
@synthesize emptyStateLabel = _emptyStateLabel;
@synthesize messages = _messages;
@synthesize sendButton = _sendButton;
@synthesize currentConversationIdentifier = _currentConversationIdentifier;
@synthesize currentConversationTitle = _currentConversationTitle;
@synthesize selectedInputImage = _selectedInputImage;
@synthesize keyboardOverlapHeight = _keyboardOverlapHeight;
@synthesize requestInFlight = _requestInFlight;
@synthesize pendingStreamingMessage = _pendingStreamingMessage;
@synthesize streamingUpdateScheduled = _streamingUpdateScheduled;

+ (UIImage *)toolbarButtonBackgroundImageHighlighted:(BOOL)highlighted {
	CGRect rect = CGRectMake(0.0f, 0.0f, 54.0f, 34.0f);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();

	UIColor *topColor = (highlighted ? [UIColor colorWithRed:75.0f/255.0f green:106.0f/255.0f blue:151.0f/255.0f alpha:1.0f] : [UIColor colorWithRed:139.0f/255.0f green:166.0f/255.0f blue:203.0f/255.0f alpha:1.0f]);
	UIColor *middleColor = (highlighted ? [UIColor colorWithRed:55.0f/255.0f green:83.0f/255.0f blue:127.0f/255.0f alpha:1.0f] : [UIColor colorWithRed:86.0f/255.0f green:119.0f/255.0f blue:165.0f/255.0f alpha:1.0f]);
	UIColor *bottomColor = (highlighted ? [UIColor colorWithRed:41.0f/255.0f green:67.0f/255.0f blue:109.0f/255.0f alpha:1.0f] : [UIColor colorWithRed:55.0f/255.0f green:83.0f/255.0f blue:130.0f/255.0f alpha:1.0f]);
	UIColor *strokeColor = [UIColor colorWithRed:35.0f/255.0f green:55.0f/255.0f blue:89.0f/255.0f alpha:1.0f];

	CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.5f, 0.5f) cornerRadius:7.0f].CGPath;
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSArray *colors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)middleColor.CGColor, (id)bottomColor.CGColor, nil];
	CGFloat locations[] = {0.0f, 0.48f, 1.0f};
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, rect.size.height), 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);

	CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:(highlighted ? 0.08f : 0.30f)].CGColor);
	CGContextFillRect(context, CGRectMake(1.0f, 1.0f, rect.size.width - 2.0f, 12.0f));
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.32f].CGColor);
	CGContextMoveToPoint(context, 4.0f, 1.5f);
	CGContextAddLineToPoint(context, rect.size.width - 4.0f, 1.5f);
	CGContextStrokePath(context);
	CGContextRestoreGState(context);

	CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
	CGContextSetLineWidth(context, 1.0f);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [image stretchableImageWithLeftCapWidth:14 topCapHeight:14];
}

+ (UIImage *)cameraGlyphImage {
	CGRect rect = CGRectMake(0.0f, 0.0f, 18.0f, 14.0f);
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.95f].CGColor);
	CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.16f].CGColor);
	CGContextSetLineWidth(context, 1.5f);

	CGRect bodyRect = CGRectMake(1.0f, 3.0f, 16.0f, 10.0f);
	CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:bodyRect cornerRadius:2.0f].CGPath);
	CGContextDrawPath(context, kCGPathFillStroke);

	CGContextMoveToPoint(context, 4.0f, 3.0f);
	CGContextAddLineToPoint(context, 6.0f, 1.0f);
	CGContextAddLineToPoint(context, 10.0f, 1.0f);
	CGContextAddLineToPoint(context, 12.0f, 3.0f);
	CGContextStrokePath(context);

	CGContextStrokeEllipseInRect(context, CGRectMake(6.0f, 5.0f, 6.0f, 6.0f));
	CGContextFillEllipseInRect(context, CGRectMake(8.0f, 7.0f, 2.0f, 2.0f));

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (id)init {
	self = [super init];
	if (self) {
		_messages = [[NSMutableArray alloc] init];
		self.title = @"Chat";
	}
	return self;
}

- (CGMessage *)messageWithAuthor:(NSString *)author role:(NSString *)role type:(int)type text:(NSString *)text {
	CGMessage *message = [[[CGMessage alloc] init] autorelease];
	message.author = author;
	message.role = role;
	message.type = type;
	message.content = text;
	message.indestructible = YES;
	message.avatar = [UIImage imageNamed:(type == 1 ? @"Images/defaultUserAvatar.png" : @"Images/defaultAssistantAvatar.png")];
	message.contentHeight = (int)[CGAPIHelper heightForMessage:message width:230.0f font:[UIFont systemFontOfSize:15.0f]];
	return message;
}

- (CGFloat)readableContentWidthForBounds:(CGRect)bounds {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return MIN(bounds.size.width - 80.0f, 620.0f);
	}
	return bounds.size.width - 40.0f;
}

- (CGFloat)horizontalLayoutInsetForBounds:(CGRect)bounds {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return MAX(32.0f, floorf((bounds.size.width - 700.0f) / 2.0f));
	}
	return 0.0f;
}

- (BOOL)isTallPhoneLayoutForBounds:(CGRect)bounds {
	return (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad && bounds.size.height >= 548.0f);
}

- (void)resetToNewConversation {
	[self.messages removeAllObjects];
	self.currentConversationIdentifier = [LCConversationStore nextConversationIdentifier];
	self.currentConversationTitle = @"New Chat";
	[LCConversationStore setCurrentConversationIdentifier:self.currentConversationIdentifier];
	self.selectedInputImage = nil;
}

- (void)persistCurrentConversation {
	NSString *resolvedTitle = [LCConversationStore derivedTitleForMessages:self.messages fallback:@"New Chat"];
	self.currentConversationTitle = resolvedTitle;
	[LCConversationStore saveMessages:self.messages conversationID:self.currentConversationIdentifier title:resolvedTitle];
	[self updateBannerForCurrentState];
}

- (void)reloadConversationUI {
	self.emptyStateLabel.hidden = ([self.messages count] > 0);
	[self.chatTableView reloadData];
	[self layoutForCurrentBounds];
	[self scrollToBottomAnimated:NO];
}

- (void)updateInputPlaceholderVisibility {
	BOOL shouldHidePlaceholder = [self.inputField isFirstResponder] || [self.inputField.text length] > 0;
	self.inputPlaceholderLabel.hidden = shouldHidePlaceholder;
}

- (void)flushPendingStreamingUpdate {
	self.streamingUpdateScheduled = NO;
	if (self.pendingStreamingMessage == nil) {
		return;
	}

	NSUInteger messageIndex = [self.messages indexOfObjectIdenticalTo:self.pendingStreamingMessage];
	self.pendingStreamingMessage = nil;
	[self persistCurrentConversation];
	if (messageIndex == NSNotFound) {
		[self.chatTableView reloadData];
		[self scrollToBottomAnimated:NO];
		return;
	}

	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messageIndex inSection:0];
	NSArray *visibleIndexPaths = [self.chatTableView indexPathsForVisibleRows];
	if ([visibleIndexPaths containsObject:indexPath]) {
		[self.chatTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[self.chatTableView reloadData];
	}
	[self scrollToBottomAnimated:NO];
}

- (void)restoreSavedConversationIfAvailable {
	NSString *savedIdentifier = [LCConversationStore currentConversationIdentifier];
	CGConversation *savedConversation = [LCConversationStore loadConversationWithIdentifier:savedIdentifier];
	if (savedConversation != nil && [savedConversation.messages count] > 0) {
		self.currentConversationIdentifier = savedConversation.uuid;
		self.currentConversationTitle = savedConversation.title;
		[self.messages removeAllObjects];
		[self.messages addObjectsFromArray:savedConversation.messages];
		return;
	}

	[self resetToNewConversation];
}

- (NSString *)currentModelDisplayText {
	NSString *providerName = [CGAPIHelper providerDisplayName];
	NSString *modelName = [CGAPIHelper configuredChatModel];
	if ([providerName length] > 0 && [modelName length] > 0) {
		return [NSString stringWithFormat:@"%@ · %@", providerName, modelName];
	}
	return ([modelName length] > 0 ? modelName : @"No model selected");
}

- (void)updateModelNameLabel {
	self.modelNameLabel.text = [self currentModelDisplayText];
}

- (void)loadView {
	[super loadView];

	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.view.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];

	UITableView *tableView = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableView.backgroundColor = [UIColor colorWithWhite:0.93f alpha:1.0f];
	tableView.delegate = self;
	tableView.dataSource = self;
	if ([tableView respondsToSelector:@selector(setKeyboardDismissMode:)]) {
		tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	}
	self.chatTableView = tableView;
	[self.view addSubview:self.chatTableView];

	UILabel *modelNameLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	modelNameLabel.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.0f];
	modelNameLabel.textAlignment = NSTextAlignmentCenter;
	modelNameLabel.font = [UIFont systemFontOfSize:12.0f];
	modelNameLabel.textColor = [UIColor colorWithWhite:0.38f alpha:1.0f];
	self.modelNameLabel = modelNameLabel;
	[self.view addSubview:self.modelNameLabel];

	UIToolbar *toolbar = [[[UIToolbar alloc] initWithFrame:CGRectZero] autorelease];
	self.toolbar = toolbar;
	[self.view addSubview:self.toolbar];

	UIButton *attachButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	attachButton.frame = CGRectZero;
	attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
	attachButton.frame = CGRectZero;
	[attachButton setBackgroundImage:[[self class] toolbarButtonBackgroundImageHighlighted:NO] forState:UIControlStateNormal];
	[attachButton setBackgroundImage:[[self class] toolbarButtonBackgroundImageHighlighted:YES] forState:UIControlStateHighlighted];
	[attachButton setImage:[[self class] cameraGlyphImage] forState:UIControlStateNormal];
	attachButton.adjustsImageWhenHighlighted = NO;
	attachButton.imageEdgeInsets = UIEdgeInsetsMake(9.0f, 13.0f, 9.0f, 13.0f);
	[attachButton addTarget:self action:@selector(attachButtonTapped) forControlEvents:UIControlEventTouchUpInside];
	self.attachButton = attachButton;
	[self.toolbar addSubview:self.attachButton];

	UIView *inputContainer = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	inputContainer.backgroundColor = [UIColor clearColor];
	self.inputContainerView = inputContainer;
	[self.toolbar addSubview:self.inputContainerView];

	UIImageView *inputOverlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Images/inputOverlay.png"]] autorelease];
	self.inputOverlayView = inputOverlay;
	[self.inputContainerView addSubview:self.inputOverlayView];

	UITextView *inputField = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
	inputField.backgroundColor = [UIColor clearColor];
	inputField.font = [UIFont systemFontOfSize:15.0f];
	inputField.textColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
	inputField.delegate = self;
	inputField.contentInset = UIEdgeInsetsMake(-3.0f, 0.0f, 0.0f, 0.0f);
	inputField.returnKeyType = UIReturnKeyDefault;
	self.inputField = inputField;
	[self.inputContainerView addSubview:self.inputField];

	UILabel *placeholder = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	placeholder.backgroundColor = [UIColor clearColor];
	placeholder.textColor = [UIColor colorWithWhite:0.45f alpha:1.0f];
	placeholder.font = [UIFont systemFontOfSize:15.0f];
	placeholder.text = @"Think of something...";
	placeholder.userInteractionEnabled = NO;
	self.inputPlaceholderLabel = placeholder;
	[self.inputContainerView addSubview:self.inputPlaceholderLabel];

	UITapGestureRecognizer *inputTapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusInputField)] autorelease];
	inputTapGesture.cancelsTouchesInView = NO;
	inputTapGesture.delaysTouchesBegan = NO;
	inputTapGesture.delaysTouchesEnded = NO;
	[self.inputContainerView addGestureRecognizer:inputTapGesture];

	UIView *attachmentPreviewContainer = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	attachmentPreviewContainer.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.92f];
	attachmentPreviewContainer.hidden = YES;
	self.attachmentPreviewContainer = attachmentPreviewContainer;
	[self.view addSubview:self.attachmentPreviewContainer];

	UIImageView *attachmentPreviewImageView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	attachmentPreviewImageView.contentMode = UIViewContentModeScaleAspectFill;
	attachmentPreviewImageView.clipsToBounds = YES;
	attachmentPreviewImageView.layer.cornerRadius = 6.0f;
	attachmentPreviewImageView.layer.borderWidth = 1.0f;
	attachmentPreviewImageView.layer.borderColor = [UIColor colorWithWhite:0.78f alpha:1.0f].CGColor;
	self.attachmentPreviewImageView = attachmentPreviewImageView;
	[self.attachmentPreviewContainer addSubview:self.attachmentPreviewImageView];

	UIButton *attachmentRemoveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	attachmentRemoveButton.frame = CGRectZero;
	[attachmentRemoveButton setTitle:@"Remove Photo" forState:UIControlStateNormal];
	[attachmentRemoveButton addTarget:self action:@selector(removeSelectedImage) forControlEvents:UIControlEventTouchUpInside];
	self.attachmentRemoveButton = attachmentRemoveButton;
	[self.attachmentPreviewContainer addSubview:self.attachmentRemoveButton];

	UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
	sendButton.frame = CGRectZero;
	[sendButton setTitle:@"Send" forState:UIControlStateNormal];
	[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[sendButton setTitleColor:[UIColor colorWithWhite:0.92f alpha:1.0f] forState:UIControlStateHighlighted];
	[sendButton setTitleShadowColor:[UIColor colorWithRed:35.0f/255.0f green:58.0f/255.0f blue:92.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
	sendButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
	sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
	[sendButton setBackgroundImage:[[self class] toolbarButtonBackgroundImageHighlighted:NO] forState:UIControlStateNormal];
	[sendButton setBackgroundImage:[[self class] toolbarButtonBackgroundImageHighlighted:YES] forState:UIControlStateHighlighted];
	[sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
	self.sendButton = sendButton;
	[self.toolbar addSubview:self.sendButton];

	UILabel *emptyStateLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	emptyStateLabel.backgroundColor = [UIColor clearColor];
	emptyStateLabel.textAlignment = NSTextAlignmentCenter;
	emptyStateLabel.numberOfLines = 0;
	emptyStateLabel.font = [UIFont systemFontOfSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 17.0f : 15.0f)];
	emptyStateLabel.textColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
	emptyStateLabel.text = @"Start a new conversation.\nType a message below to chat with your configured provider.";
	self.emptyStateLabel = emptyStateLabel;
	[self.view addSubview:self.emptyStateLabel];

	UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)] autorelease];
	tapGesture.cancelsTouchesInView = NO;
	[self.chatTableView addGestureRecognizer:tapGesture];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiResponseReceived:) name:LCAPIResponseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiMessageDidUpdate:) name:LCAPIMessageDidUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiStatusDidChange:) name:LCAPIStatusDidChangeNotification object:nil];

	CGFloat titleWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 132.0f : 104.0f);
	UIView *titleView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, titleWidth, 24.0f)] autorelease];
	titleView.backgroundColor = [UIColor clearColor];
	self.navigationTitleView = titleView;

	UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, 2.0f, titleWidth, 20.0f)] autorelease];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.textColor = [UIColor colorWithWhite:0.18f alpha:1.0f];
	titleLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.75f];
	titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
	titleLabel.text = @"Chat";
	self.navigationTitleLabel = titleLabel;
	[self.navigationTitleView addSubview:self.navigationTitleLabel];

	UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	spinner.frame = CGRectMake(floorf((titleWidth + 42.0f) / 2.0f), 2.0f, 20.0f, 20.0f);
	spinner.hidesWhenStopped = YES;
	self.navigationSpinner = spinner;
	[self.navigationTitleView addSubview:self.navigationSpinner];
	self.navigationItem.titleView = self.navigationTitleView;

	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Chats" style:UIBarButtonItemStyleBordered target:self action:@selector(showConversations)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings)] autorelease];

	[self resetToNewConversation];
	[self updateBannerForCurrentState];
	[self updateModelNameLabel];
	[self reloadConversationUI];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateModelNameLabel];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutForCurrentBounds];
}

- (void)layoutForCurrentBounds {
	CGRect bounds = self.view.bounds;
	CGFloat toolbarHeight = 44.0f;
	CGFloat modelLabelHeight = 22.0f;
	CGFloat attachmentHeight = (self.selectedInputImage != nil ? 70.0f : 0.0f);
	CGFloat bottomInset = self.keyboardOverlapHeight;
	CGFloat horizontalInset = [self horizontalLayoutInsetForBounds:bounds];
	CGFloat contentWidth = bounds.size.width - (horizontalInset * 2.0f);

	self.attachmentPreviewContainer.hidden = (self.selectedInputImage == nil);
	self.attachmentPreviewContainer.frame = CGRectMake(horizontalInset, bounds.size.height - bottomInset - toolbarHeight - attachmentHeight, contentWidth, attachmentHeight);
	self.attachmentPreviewImageView.frame = CGRectMake(10.0f, 8.0f, 72.0f, 54.0f);
	self.attachmentRemoveButton.frame = CGRectMake(92.0f, 18.0f, 120.0f, 30.0f);

	self.toolbar.frame = CGRectMake(horizontalInset, bounds.size.height - bottomInset - toolbarHeight, contentWidth, toolbarHeight);
	self.modelNameLabel.frame = CGRectMake(horizontalInset, 0.0f, contentWidth, modelLabelHeight);
	self.chatTableView.frame = CGRectMake(horizontalInset, modelLabelHeight, contentWidth, bounds.size.height - modelLabelHeight - toolbarHeight - attachmentHeight - bottomInset);
	CGFloat readableWidth = [self readableContentWidthForBounds:self.chatTableView.bounds];
	CGFloat emptyStateY = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 180.0f : ([self isTallPhoneLayoutForBounds:bounds] ? 145.0f : 110.0f));
	self.emptyStateLabel.frame = CGRectMake(horizontalInset + floorf((contentWidth - readableWidth) / 2.0f), modelLabelHeight + emptyStateY, readableWidth, 56.0f);
	self.emptyStateLabel.hidden = ([self.messages count] > 0);

	CGFloat attachWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 64.0f : 58.0f);
	CGFloat sendWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 76.0f : 68.0f);
	CGFloat toolbarPadding = 6.0f;
	CGFloat inputX = toolbarPadding + attachWidth + 6.0f;
	CGFloat inputWidth = contentWidth - inputX - sendWidth - 12.0f;
	if (inputWidth < 120.0f) {
		inputWidth = 120.0f;
	}
	self.attachButton.frame = CGRectMake(toolbarPadding, 5.0f, attachWidth, 34.0f);
	self.sendButton.frame = CGRectMake(contentWidth - sendWidth - toolbarPadding, 5.0f, sendWidth, 34.0f);
	self.inputContainerView.frame = CGRectMake(inputX, 7.0f, inputWidth, 30.0f);
	self.inputOverlayView.frame = self.inputContainerView.bounds;
	self.inputField.frame = CGRectMake(10.0f, 4.0f, inputWidth - 20.0f, 22.0f);
	self.inputPlaceholderLabel.frame = CGRectMake(16.0f, 6.0f, inputWidth - 28.0f, 18.0f);
	[self updateInputPlaceholderVisibility];
}

- (void)dismissKeyboard {
	[self.inputField resignFirstResponder];
}

- (void)focusInputField {
	if (!self.requestInFlight && ![self.inputField isFirstResponder]) {
		[self.inputField becomeFirstResponder];
	}
}

- (void)sendTapped {
	NSString *trimmedText = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ((trimmedText.length == 0 && self.selectedInputImage == nil) || self.requestInFlight) {
		return;
	}

	CGMessage *outgoingMessage = [self messageWithAuthor:@"You" role:@"user" type:1 text:trimmedText];
	outgoingMessage.imageAttachment = self.selectedInputImage;
	[self.messages addObject:outgoingMessage];
	[self persistCurrentConversation];
	self.inputField.text = @"";
	self.emptyStateLabel.hidden = YES;
	self.selectedInputImage = nil;
	[self updateInputPlaceholderVisibility];

	[self.chatTableView reloadData];
	[self scrollToBottomAnimated:YES];
	[self dismissKeyboard];
	[CGAPICommunicator createChatCompletionWithMessages:self.messages];
}

- (void)showConversations {
	LCConversationsViewController *controller = [[[LCConversationsViewController alloc] init] autorelease];
	controller.delegate = self;
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)showSettings {
	LCSettingsViewController *controller = [[[LCSettingsViewController alloc] init] autorelease];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)startNewConversation {
	if (self.requestInFlight) {
		return;
	}

	[self dismissKeyboard];
	[self resetToNewConversation];
	[self updateBannerForCurrentState];
	[self reloadConversationUI];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
	if ([self.messages count] == 0) {
		return;
	}

	NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:[self.messages count] - 1 inSection:0];
	[self.chatTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)apiResponseReceived:(NSNotification *)notification {
	CGMessage *message = [notification object];
	if (![message isKindOfClass:[CGMessage class]]) {
		return;
	}

	if ([self.messages indexOfObjectIdenticalTo:message] == NSNotFound) {
		[self.messages addObject:message];
	}
	[self persistCurrentConversation];
	self.emptyStateLabel.hidden = YES;
	[self.chatTableView reloadData];
	[self scrollToBottomAnimated:YES];
}

- (void)apiMessageDidUpdate:(NSNotification *)notification {
	CGMessage *message = [notification object];
	if (![message isKindOfClass:[CGMessage class]]) {
		return;
	}

	if ([self.messages indexOfObjectIdenticalTo:message] == NSNotFound) {
		[self.messages addObject:message];
	}
	self.pendingStreamingMessage = message;
	if (!self.streamingUpdateScheduled) {
		self.streamingUpdateScheduled = YES;
		[self performSelector:@selector(flushPendingStreamingUpdate) withObject:nil afterDelay:0.12];
	}
}

- (void)apiStatusDidChange:(NSNotification *)notification {
	self.requestInFlight = [[notification object] boolValue];
	if (!self.requestInFlight && self.streamingUpdateScheduled) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(flushPendingStreamingUpdate) object:nil];
		[self flushPendingStreamingUpdate];
	}
	self.sendButton.enabled = !self.requestInFlight;
	self.attachButton.enabled = !self.requestInFlight;
	self.inputField.editable = !self.requestInFlight;
	[self updateBannerForCurrentState];
}

- (void)conversationsViewControllerDidRequestNewChat:(LCConversationsViewController *)controller {
	[self.navigationController popViewControllerAnimated:YES];
	[self startNewConversation];
}

- (void)conversationsViewController:(LCConversationsViewController *)controller didSelectConversation:(CGConversation *)conversation {
	[self.navigationController popViewControllerAnimated:YES];
	if (conversation == nil || [conversation.messages count] == 0) {
		return;
	}

	self.currentConversationIdentifier = conversation.uuid;
	self.currentConversationTitle = conversation.title;
	[LCConversationStore setCurrentConversationIdentifier:conversation.uuid];
	[self.messages removeAllObjects];
	[self.messages addObjectsFromArray:conversation.messages];
	[self updateBannerForCurrentState];
	[self reloadConversationUI];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.messages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGMessage *message = [self.messages objectAtIndex:indexPath.row];
	if (message.type == 1) {
		return [CGAuthorTableCell heightForMessage:message width:tableView.bounds.size.width];
	}
	return [CGChatTableCell heightForMessage:message width:tableView.bounds.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGMessage *message = [self.messages objectAtIndex:indexPath.row];
	if (message.type == 1) {
		static NSString *AuthorCellIdentifier = @"AuthorCell";
		CGAuthorTableCell *cell = (CGAuthorTableCell *)[tableView dequeueReusableCellWithIdentifier:AuthorCellIdentifier];
		if (cell == nil) {
			cell = [[[CGAuthorTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AuthorCellIdentifier] autorelease];
		}
		[cell configureWithAuthor:(message.author ?: @"You") message:message avatar:message.avatar];
		return cell;
	}

	static NSString *MessageCellIdentifier = @"MessageCell";
	CGChatTableCell *cell = (CGChatTableCell *)[tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
	if (cell == nil) {
		cell = [[[CGChatTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MessageCellIdentifier] autorelease];
	}
	[cell configureWithAuthor:(message.author ?: @"Assistant") message:message avatar:message.avatar];
	return cell;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[self updateInputPlaceholderVisibility];
}

- (void)textViewDidChange:(UITextView *)textView {
	[self updateInputPlaceholderVisibility];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self updateInputPlaceholderVisibility];
}

- (void)updateBannerForCurrentState {
	if (self.requestInFlight) {
		[self.navigationSpinner startAnimating];
	} else {
		[self.navigationSpinner stopAnimating];
	}
	[self updateModelNameLabel];
}

- (void)setSelectedInputImage:(UIImage *)selectedInputImage {
	if (_selectedInputImage == selectedInputImage) {
		return;
	}
	[_selectedInputImage release];
	_selectedInputImage = [selectedInputImage retain];
	self.attachmentPreviewImageView.image = _selectedInputImage;
	[self layoutForCurrentBounds];
}

- (void)attachButtonTapped {
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"Attach Image"
		delegate:self
		cancelButtonTitle:@"Cancel"
		destructiveButtonTitle:nil
		otherButtonTitles:nil] autorelease];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		[sheet addButtonWithTitle:@"Photo Library"];
	}
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[sheet addButtonWithTitle:@"Camera"];
	}
	if (self.selectedInputImage != nil) {
		[sheet addButtonWithTitle:@"Remove Current Photo"];
	}
	[sheet showInView:self.view];
}

- (void)removeSelectedImage {
	self.selectedInputImage = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:@"Photo Library"]) {
		[self presentImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
	} else if ([buttonTitle isEqualToString:@"Camera"]) {
		[self presentImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
	} else if ([buttonTitle isEqualToString:@"Remove Current Photo"]) {
		[self removeSelectedImage];
	}
}

- (void)presentImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
	if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
		return;
	}

	UIImagePickerController *picker = [[[UIImagePickerController alloc] init] autorelease];
	picker.delegate = self;
	picker.sourceType = sourceType;
	picker.allowsEditing = NO;
	[self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.selectedInputImage = selectedImage;
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	CGRect convertedKeyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
	CGRect intersection = CGRectIntersection(self.view.bounds, convertedKeyboardFrame);
	CGFloat keyboardHeight = CGRectIsNull(intersection) ? 0.0f : intersection.size.height;
	self.keyboardOverlapHeight = keyboardHeight;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	[self layoutForCurrentBounds];
	[UIView commitAnimations];

	if ([self.messages count] > 0) {
		[self scrollToBottomAnimated:NO];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification {
	NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	self.keyboardOverlapHeight = 0.0f;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	[self layoutForCurrentBounds];
	[UIView commitAnimations];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self dismissKeyboard];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_chatTableView release];
	[_navigationTitleView release];
	[_navigationTitleLabel release];
	[_navigationSpinner release];
	[_modelNameLabel release];
	[_toolbar release];
	[_attachButton release];
	[_inputContainerView release];
	[_inputOverlayView release];
	[_inputField release];
	[_inputPlaceholderLabel release];
	[_attachmentPreviewContainer release];
	[_attachmentPreviewImageView release];
	[_attachmentRemoveButton release];
	[_emptyStateLabel release];
	[_messages release];
	[_sendButton release];
	[_currentConversationIdentifier release];
	[_currentConversationTitle release];
	[_selectedInputImage release];
	[_pendingStreamingMessage release];
	[super dealloc];
}

@end
