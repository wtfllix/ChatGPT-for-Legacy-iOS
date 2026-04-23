#import "CGChatTableCell.h"
#import "CGAPIHelper.h"
#import <QuartzCore/QuartzCore.h>

@implementation CGChatTableCell

@synthesize avatar = _avatar;
@synthesize authorLabel = _authorLabel;
@synthesize thinkingBackgroundView = _thinkingBackgroundView;
@synthesize contentLabel = _contentLabel;
@synthesize attachmentPreview = _attachmentPreview;
@synthesize separator = _separator;
@synthesize iOS7Separator = _iOS7Separator;

+ (CGFloat)boundedTextWidthForCellWidth:(CGFloat)width {
	CGFloat availableWidth = width - 70.0f;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return MIN(availableWidth, 700.0f);
	}
	return availableWidth;
}

+ (CGFloat)heightForMessage:(CGMessage *)message width:(CGFloat)width {
	CGFloat textWidth = [self boundedTextWidthForCellWidth:width];
	return [CGAPIHelper heightForMessage:message width:textWidth font:[UIFont systemFontOfSize:15.0f]];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.backgroundColor = [UIColor whiteColor];

		_avatar = [[UIImageView alloc] initWithFrame:CGRectMake(11.0f, 12.0f, 38.0f, 38.0f)];
		_avatar.layer.cornerRadius = 6.0f;
		_avatar.layer.masksToBounds = YES;
		[self.contentView addSubview:_avatar];

		_authorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_authorLabel.backgroundColor = [UIColor clearColor];
		_authorLabel.font = [UIFont boldSystemFontOfSize:15.0f];
			_authorLabel.textColor = [UIColor colorWithRed:74.0f/255.0f green:125.0f/255.0f blue:112.0f/255.0f alpha:1.0f];
			[self.contentView addSubview:_authorLabel];

			_thinkingBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
			_thinkingBackgroundView.hidden = YES;
			_thinkingBackgroundView.backgroundColor = [UIColor colorWithRed:251.0f/255.0f green:246.0f/255.0f blue:224.0f/255.0f alpha:1.0f];
			_thinkingBackgroundView.layer.cornerRadius = 8.0f;
			_thinkingBackgroundView.layer.borderWidth = 1.0f;
			_thinkingBackgroundView.layer.borderColor = [UIColor colorWithRed:224.0f/255.0f green:205.0f/255.0f blue:140.0f/255.0f alpha:1.0f].CGColor;
			[self.contentView addSubview:_thinkingBackgroundView];

			_contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			_contentLabel.backgroundColor = [UIColor clearColor];
			_contentLabel.font = [UIFont systemFontOfSize:15.0f];
			_contentLabel.textColor = [UIColor colorWithWhite:0.24f alpha:1.0f];
			_contentLabel.numberOfLines = 0;
		[self.contentView addSubview:_contentLabel];

		_attachmentPreview = [[UIImageView alloc] initWithFrame:CGRectZero];
		_attachmentPreview.contentMode = UIViewContentModeScaleAspectFill;
		_attachmentPreview.clipsToBounds = YES;
		_attachmentPreview.layer.cornerRadius = 6.0f;
		_attachmentPreview.layer.borderWidth = 1.0f;
		_attachmentPreview.layer.borderColor = [UIColor colorWithWhite:0.80f alpha:1.0f].CGColor;
		_attachmentPreview.hidden = YES;
		[self.contentView addSubview:_attachmentPreview];

		_separator = [[UIImageView alloc] initWithFrame:CGRectZero];
		_separator.backgroundColor = [UIColor colorWithWhite:0.88f alpha:1.0f];
		[self.contentView addSubview:_separator];

		_iOS7Separator = [[UIImageView alloc] initWithFrame:CGRectZero];
		_iOS7Separator.hidden = YES;
		[self.contentView addSubview:_iOS7Separator];
	}
	return self;
}

- (void)configureWithAuthor:(NSString *)author
                    message:(CGMessage *)message
                     avatar:(UIImage *)avatarImage {
	BOOL isShowingThinking = ([message.hiddenReasoningContent length] > 0 && [message.content isEqualToString:message.hiddenReasoningContent]);
	self.authorLabel.text = (isShowingThinking ? @"Thinking" : author);
	self.authorLabel.textColor = (isShowingThinking
		? [UIColor colorWithRed:128.0f/255.0f green:101.0f/255.0f blue:36.0f/255.0f alpha:1.0f]
		: [UIColor colorWithRed:74.0f/255.0f green:125.0f/255.0f blue:112.0f/255.0f alpha:1.0f]);
	self.thinkingBackgroundView.hidden = !isShowingThinking;
	self.contentLabel.textColor = (isShowingThinking
		? [UIColor colorWithRed:92.0f/255.0f green:76.0f/255.0f blue:34.0f/255.0f alpha:1.0f]
		: [UIColor colorWithWhite:0.24f alpha:1.0f]);
	if ([self.contentLabel respondsToSelector:@selector(setAttributedText:)]) {
		self.contentLabel.attributedText = [CGAPIHelper attributedDisplayStringForMessage:message font:self.contentLabel.font textColor:self.contentLabel.textColor];
	} else {
		self.contentLabel.text = [CGAPIHelper displayTextForMessage:message];
	}
	self.avatar.image = avatarImage;
	self.attachmentPreview.image = message.imageAttachment;
	self.attachmentPreview.hidden = (message.imageAttachment == nil);
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat contentX = 58.0f;
	CGFloat contentWidth = [[self class] boundedTextWidthForCellWidth:self.contentView.bounds.size.width];
	NSString *displayText = ([self.contentLabel.attributedText length] > 0 ? [self.contentLabel.attributedText string] : (self.contentLabel.text ?: @""));
	CGSize textSize = [displayText sizeWithFont:self.contentLabel.font
	                                     constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
	                                         lineBreakMode:NSLineBreakByWordWrapping];

	 self.avatar.frame = CGRectMake(11.0f, 12.0f, 38.0f, 38.0f);
	self.authorLabel.frame = CGRectMake(contentX, 10.0f, contentWidth, 18.0f);
	self.contentLabel.frame = CGRectMake(contentX, 29.0f, contentWidth, textSize.height + 2.0f);
	if (!self.attachmentPreview.hidden) {
		self.attachmentPreview.frame = CGRectMake(contentX, CGRectGetMaxY(self.contentLabel.frame) + 8.0f, 72.0f, 54.0f);
	} else {
		self.attachmentPreview.frame = CGRectZero;
	}
	if (!self.thinkingBackgroundView.hidden) {
		CGFloat thinkingBottom = (!self.attachmentPreview.hidden ? CGRectGetMaxY(self.attachmentPreview.frame) : CGRectGetMaxY(self.contentLabel.frame));
		self.thinkingBackgroundView.frame = CGRectMake(contentX - 8.0f, 26.0f, contentWidth + 12.0f, MAX(30.0f, thinkingBottom - 22.0f));
	} else {
		self.thinkingBackgroundView.frame = CGRectZero;
	}
	self.separator.frame = CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width, 1.0f);
	self.separator.hidden = NO;
}

- (void)dealloc {
	[_avatar release];
	[_authorLabel release];
	[_thinkingBackgroundView release];
	[_contentLabel release];
	[_attachmentPreview release];
	[_separator release];
	[_iOS7Separator release];
	[super dealloc];
}

@end
