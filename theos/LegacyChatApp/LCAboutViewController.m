#import "LCAboutViewController.h"

static NSString * const LCAboutRepositoryURLString = @"https://github.com/wtfllix/ChatGPT-for-Legacy-iOS";

@implementation LCAboutViewController

- (id)init {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = @"About";
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.rowHeight = 56.0f;
	}
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return @"Legacy-Chatbox is built for legacy iOS 6 devices.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"AboutCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
	}

	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
	cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
	cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.32f alpha:1.0f];

	if (indexPath.row == 0) {
		cell.textLabel.text = @"Name";
		cell.detailTextLabel.text = @"Legacy-Chatbox";
	} else if (indexPath.row == 1) {
		cell.textLabel.text = @"Version";
		cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"0.1.0";
	} else {
		cell.textLabel.text = @"Repository";
		cell.detailTextLabel.text = @"GitHub";
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row != 2) {
		return;
	}

	NSURL *url = [NSURL URLWithString:LCAboutRepositoryURLString];
	if (url != nil && [[UIApplication sharedApplication] canOpenURL:url]) {
		[[UIApplication sharedApplication] openURL:url];
	}
}

@end
