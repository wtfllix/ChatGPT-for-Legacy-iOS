#import "LCProviderProfilesViewController.h"
#import "CGAPIHelper.h"
#import "LCProviderProfileEditorViewController.h"

@interface LCProviderProfilesViewController ()

@property (nonatomic, retain) NSMutableArray *profiles;

@end

@implementation LCProviderProfilesViewController

@synthesize profiles = _profiles;

- (id)init {
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.title = @"Model Configurations";
		self.profiles = [NSMutableArray array];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.rowHeight = 56.0f;
	}
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)] autorelease];
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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.profiles = [NSMutableArray arrayWithArray:[CGAPIHelper providerProfiles]];
	[self.tableView reloadData];
}

- (void)addTapped {
	LCProviderProfileEditorViewController *controller = [[[LCProviderProfileEditorViewController alloc] initForNewProfile] autorelease];
	[self.navigationController pushViewController:controller animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return MAX((NSInteger)[self.profiles count], 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return @"Tap a configuration row to make it active. Tap the disclosure button to edit an existing configuration.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ProfileCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}

	if ([self.profiles count] == 0) {
		cell.textLabel.text = @"No model configurations yet";
		cell.detailTextLabel.text = @"Tap + to add your first provider.";
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.imageView.image = nil;
		return cell;
	}

	NSDictionary *profile = [self.profiles objectAtIndex:indexPath.row];
	cell.textLabel.text = [profile objectForKey:@"providerName"];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@",
		([profile objectForKey:@"c-aiModel"] ?: @""),
		([profile objectForKey:@"baseURL"] ?: @"")];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	if ([[[profile objectForKey:@"identifier"] description] isEqualToString:[CGAPIHelper activeProviderProfileIdentifier]]) {
		cell.imageView.image = nil;
		cell.textLabel.text = [NSString stringWithFormat:@"✓ %@", [profile objectForKey:@"providerName"]];
	} else {
		cell.imageView.image = nil;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ([self.profiles count] == 0) {
		return;
	}

	NSDictionary *profile = [self.profiles objectAtIndex:indexPath.row];
	[CGAPIHelper activateProviderProfileWithIdentifier:[profile objectForKey:@"identifier"]];
	self.profiles = [NSMutableArray arrayWithArray:[CGAPIHelper providerProfiles]];
	[self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([self.profiles count] > 0);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle != UITableViewCellEditingStyleDelete || [self.profiles count] == 0) {
		return;
	}

	NSDictionary *profile = [self.profiles objectAtIndex:indexPath.row];
	[CGAPIHelper deleteProviderProfileWithIdentifier:[profile objectForKey:@"identifier"]];
	self.profiles = [NSMutableArray arrayWithArray:[CGAPIHelper providerProfiles]];
	[tableView reloadData];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if ([self.profiles count] == 0) {
		return;
	}

	NSDictionary *profile = [self.profiles objectAtIndex:indexPath.row];
	LCProviderProfileEditorViewController *controller = [[[LCProviderProfileEditorViewController alloc] initWithProfile:profile] autorelease];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)dealloc {
	[_profiles release];
	[super dealloc];
}

@end
