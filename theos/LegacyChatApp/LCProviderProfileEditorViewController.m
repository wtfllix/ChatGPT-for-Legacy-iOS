#import "LCProviderProfileEditorViewController.h"
#import "CGAPIHelper.h"

@interface LCProviderProfileEditorViewController ()

@property (nonatomic, retain) NSArray *fieldOrder;
@property (nonatomic, retain) NSMutableDictionary *draftValues;
@property (nonatomic, retain) NSMutableDictionary *textFields;
@property (nonatomic, retain) NSString *editingIdentifier;
@property (nonatomic, assign) BOOL creatingNewProfile;

@end

@implementation LCProviderProfileEditorViewController

@synthesize fieldOrder = _fieldOrder;
@synthesize draftValues = _draftValues;
@synthesize textFields = _textFields;
@synthesize editingIdentifier = _editingIdentifier;
@synthesize creatingNewProfile = _creatingNewProfile;

+ (NSMutableDictionary *)defaultDraftValues {
	NSMutableDictionary *values = [NSMutableDictionary dictionary];
	[values setObject:@"AI Assistant" forKey:@"providerName"];
	[values setObject:@"https://api.openai.com" forKey:@"baseURL"];
	[values setObject:@"/v1/chat/completions" forKey:@"chatPath"];
	[values setObject:@"gpt-4o-mini" forKey:@"c-aiModel"];
	[values setObject:@"" forKey:@"apiKey"];
	return values;
}

- (id)initForNewProfile {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = @"New Configuration";
		self.creatingNewProfile = YES;
		self.fieldOrder = [NSArray arrayWithObjects:@"providerName", @"baseURL", @"chatPath", @"c-aiModel", @"apiKey", nil];
		self.draftValues = [[self class] defaultDraftValues];
		self.textFields = [NSMutableDictionary dictionary];
	}
	return self;
}

- (id)initWithProfile:(NSDictionary *)profile {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = @"Edit Configuration";
		self.creatingNewProfile = NO;
		self.editingIdentifier = [profile objectForKey:@"identifier"];
		self.fieldOrder = [NSArray arrayWithObjects:@"providerName", @"baseURL", @"chatPath", @"c-aiModel", @"apiKey", nil];
		self.draftValues = [[self class] defaultDraftValues];
		if ([profile isKindOfClass:[NSDictionary class]]) {
			[self.draftValues addEntriesFromDictionary:profile];
		}
		self.textFields = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.rowHeight = 68.0f;
	}
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)] autorelease];
	[self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		return;
	}

	CGRect bounds = self.view.bounds;
	CGFloat tableWidth = MIN(560.0f, bounds.size.width - 80.0f);
	self.tableView.frame = CGRectMake(floorf((bounds.size.width - tableWidth) / 2.0f), 0.0f, tableWidth, bounds.size.height);
}

- (NSString *)titleForFieldKey:(NSString *)fieldKey {
	if ([fieldKey isEqualToString:@"providerName"]) return @"Provider";
	if ([fieldKey isEqualToString:@"baseURL"]) return @"Base URL";
	if ([fieldKey isEqualToString:@"chatPath"]) return @"Chat Path";
	if ([fieldKey isEqualToString:@"c-aiModel"]) return @"Model";
	if ([fieldKey isEqualToString:@"apiKey"]) return @"API Key";
	return fieldKey;
}

- (NSString *)placeholderForFieldKey:(NSString *)fieldKey {
	if ([fieldKey isEqualToString:@"providerName"]) return @"DeepSeek";
	if ([fieldKey isEqualToString:@"baseURL"]) return @"https://api.deepseek.com";
	if ([fieldKey isEqualToString:@"chatPath"]) return @"/chat/completions";
	if ([fieldKey isEqualToString:@"c-aiModel"]) return @"deepseek-chat";
	if ([fieldKey isEqualToString:@"apiKey"]) return @"Paste your key";
	return @"";
}

- (void)saveTapped {
	[self.view endEditing:YES];
	if (self.creatingNewProfile) {
		[CGAPIHelper createProviderProfileWithValues:self.draftValues];
	} else {
		[CGAPIHelper updateProviderProfileWithIdentifier:self.editingIdentifier values:self.draftValues];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.fieldOrder count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return @"Base URL should be the provider root. For DeepSeek, use https://api.deepseek.com and /chat/completions.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"FieldCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	UILabel *titleLabel = nil;
	UITextField *textField = nil;
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		titleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		titleLabel.tag = 9001;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textColor = [UIColor blackColor];
		titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
		titleLabel.highlightedTextColor = [UIColor blackColor];
		[cell.contentView addSubview:titleLabel];

		textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
		textField.tag = 9002;
		textField.textColor = [UIColor blackColor];
		textField.opaque = NO;
		textField.borderStyle = UITextBorderStyleNone;
		textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		textField.textAlignment = NSTextAlignmentLeft;
		textField.font = [UIFont systemFontOfSize:15.0f];
		textField.delegate = self;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.backgroundColor = [UIColor clearColor];
		textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[cell.contentView addSubview:textField];
	} else {
		for (UIView *subview in cell.contentView.subviews) {
			if ([subview isKindOfClass:[UILabel class]] && subview.tag == 9001) {
				titleLabel = (UILabel *)subview;
			} else if ([subview isKindOfClass:[UITextField class]] && subview.tag == 9002) {
				textField = (UITextField *)subview;
			}
		}
	}

	NSString *fieldKey = [self.fieldOrder objectAtIndex:indexPath.row];
	CGFloat rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 68.0f : 60.0f);
	CGFloat titleY = 8.0f;
	CGFloat fieldY = rowHeight - 33.0f;
	cell.textLabel.text = @"";
	cell.textLabel.hidden = YES;
	titleLabel.text = [self titleForFieldKey:fieldKey];
	titleLabel.frame = CGRectMake(20.0f, titleY, tableView.bounds.size.width - 40.0f, 18.0f);
	textField.tag = indexPath.row + 100;
	textField.placeholder = [self placeholderForFieldKey:fieldKey];
	NSString *fieldValue = [self.draftValues objectForKey:fieldKey];
	textField.secureTextEntry = NO;
	textField.text = ([fieldValue isKindOfClass:[NSString class]] ? fieldValue : @"");
	textField.secureTextEntry = [fieldKey isEqualToString:@"apiKey"];
	textField.keyboardType = ([fieldKey isEqualToString:@"baseURL"] ? UIKeyboardTypeURL : UIKeyboardTypeDefault);
	textField.returnKeyType = (indexPath.row == [self.fieldOrder count] - 1 ? UIReturnKeyDone : UIReturnKeyNext);
	textField.frame = CGRectMake(20.0f, fieldY, tableView.bounds.size.width - 40.0f, 26.0f);
	[self.textFields setObject:textField forKey:fieldKey];
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![cell.reuseIdentifier isEqualToString:@"FieldCell"]) {
		return;
	}

	UITextField *textField = nil;
	for (UIView *subview in cell.contentView.subviews) {
		if ([subview isKindOfClass:[UITextField class]]) {
			textField = (UITextField *)subview;
			break;
		}
	}
	if (textField == nil) {
		return;
	}

	NSString *fieldKey = [self.fieldOrder objectAtIndex:indexPath.row];
	NSString *fieldValue = [self.draftValues objectForKey:fieldKey];
	CGFloat rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 68.0f : 60.0f);
	CGFloat titleY = 8.0f;
	CGFloat fieldY = rowHeight - 33.0f;
	UILabel *titleLabel = nil;
	for (UIView *subview in cell.contentView.subviews) {
		if ([subview isKindOfClass:[UILabel class]] && subview.tag == 9001) {
			titleLabel = (UILabel *)subview;
			break;
		}
	}
	cell.textLabel.text = @"";
	cell.textLabel.hidden = YES;
	titleLabel.text = [self titleForFieldKey:fieldKey];
	titleLabel.frame = CGRectMake(20.0f, titleY, tableView.bounds.size.width - 40.0f, 18.0f);
	textField.frame = CGRectMake(20.0f, fieldY, tableView.bounds.size.width - 40.0f, 26.0f);
	textField.placeholder = [self placeholderForFieldKey:fieldKey];
	textField.textColor = [UIColor blackColor];
	textField.backgroundColor = [UIColor clearColor];
	textField.textAlignment = NSTextAlignmentLeft;
	textField.secureTextEntry = NO;
	textField.text = ([fieldValue isKindOfClass:[NSString class]] ? fieldValue : @"");
	textField.secureTextEntry = [fieldKey isEqualToString:@"apiKey"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 68.0f : 60.0f);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString *fieldKey = [self.fieldOrder objectAtIndex:indexPath.row];
	UITextField *textField = [self.textFields objectForKey:fieldKey];
	[textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSInteger nextTag = textField.tag + 1;
	UIView *nextView = [self.view viewWithTag:nextTag];
	if ([nextView isKindOfClass:[UITextField class]]) {
		[(UITextField *)nextView becomeFirstResponder];
	} else {
		[textField resignFirstResponder];
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSInteger fieldIndex = textField.tag - 100;
	if (fieldIndex < 0 || fieldIndex >= [self.fieldOrder count]) {
		return;
	}
	NSString *fieldKey = [self.fieldOrder objectAtIndex:fieldIndex];
	NSString *value = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self.draftValues setObject:(value ?: @"") forKey:fieldKey];
}

- (void)dealloc {
	[_fieldOrder release];
	[_draftValues release];
	[_textFields release];
	[_editingIdentifier release];
	[super dealloc];
}

@end
