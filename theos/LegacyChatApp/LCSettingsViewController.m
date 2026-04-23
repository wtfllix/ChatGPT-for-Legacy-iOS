#import "LCSettingsViewController.h"
#import "LCProviderProfilesViewController.h"
#import "LCSystemPromptViewController.h"
#import "LCAboutViewController.h"
#import "CGAPIHelper.h"

@implementation LCSettingsViewController

- (id)init {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = @"Settings";
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.rowHeight = 56.0f;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (section == 0 ? 2 : 2);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return (section == 0 ? @"Model" : @"More");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) {
		return @"Manage providers and the optional system prompt sent before each request.";
	}
	return @"More settings can be added here later.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"SettingsCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Model Configurations";
			cell.detailTextLabel.text = @"Saved providers and active model selection";
		} else {
			NSString *systemPrompt = [CGAPIHelper configuredSystemPrompt];
			cell.textLabel.text = @"System Prompt";
			cell.detailTextLabel.text = ([systemPrompt length] > 0 ? systemPrompt : @"Disabled");
		}
	} else if (indexPath.row == 0) {
		cell.textLabel.text = @"Appearance";
		cell.detailTextLabel.text = @"Coming soon";
	} else {
		cell.textLabel.text = @"About";
		cell.detailTextLabel.text = @"Legacy-Chatbox";
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			LCProviderProfilesViewController *controller = [[[LCProviderProfilesViewController alloc] init] autorelease];
			[self.navigationController pushViewController:controller animated:YES];
		} else {
			LCSystemPromptViewController *controller = [[[LCSystemPromptViewController alloc] init] autorelease];
			[self.navigationController pushViewController:controller animated:YES];
		}
		return;
	}

	if (indexPath.row == 1) {
		LCAboutViewController *controller = [[[LCAboutViewController alloc] init] autorelease];
		[self.navigationController pushViewController:controller animated:YES];
		return;
	}

	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Coming Soon"
		message:@"This settings section is reserved for a later pass."
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil] autorelease];
	[alert show];
}

@end
