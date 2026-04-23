#import "LCConversationsViewController.h"
#import "CGConversation.h"
#import "LCConversationStore.h"

@interface LCConversationsViewController ()

@property (nonatomic, retain) NSMutableArray *conversations;
@property (nonatomic, assign) BOOL loadingConversations;

@end

@implementation LCConversationsViewController

@synthesize delegate = _delegate;
@synthesize conversations = _conversations;
@synthesize loadingConversations = _loadingConversations;

- (id)init {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		self.title = @"Chats";
	}
	return self;
}

	- (void)viewDidLoad {
		[super viewDidLoad];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.tableView.rowHeight = 56.0f;
		}
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newChatTapped)] autorelease];
	}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadConversationsAsync];
}

- (void)loadConversationsAsync {
	if (self.loadingConversations) {
		return;
	}

	self.loadingConversations = YES;
	[self.tableView reloadData];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray *loadedConversations = [LCConversationStore loadConversations];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.loadingConversations = NO;
			self.conversations = [NSMutableArray arrayWithArray:loadedConversations];
			[self.tableView reloadData];
		});
	});
}

- (void)newChatTapped {
	if ([self.delegate respondsToSelector:@selector(conversationsViewControllerDidRequestNewChat:)]) {
		[self.delegate conversationsViewControllerDidRequestNewChat:self];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.loadingConversations && [self.conversations count] == 0) {
		return 1;
	}
	return [self.conversations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ConversationCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	if (self.loadingConversations && [self.conversations count] == 0) {
		cell.textLabel.text = @"Loading Chats...";
		cell.detailTextLabel.text = @"Reading saved conversations.";
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		return cell;
	}

	CGConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
	cell.textLabel.text = conversation.title ?: @"New Chat";
	cell.detailTextLabel.text = conversation.lastTimeEdited ?: conversation.creationDate;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
	cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (self.loadingConversations && [self.conversations count] == 0) {
		return;
	}
	CGConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
	if ([self.delegate respondsToSelector:@selector(conversationsViewController:didSelectConversation:)]) {
		[self.delegate conversationsViewController:self didSelectConversation:conversation];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.loadingConversations && [self.conversations count] == 0) {
		return NO;
	}
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle != UITableViewCellEditingStyleDelete) {
		return;
	}

	CGConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
	[LCConversationStore deleteConversationWithIdentifier:conversation.uuid];
	[self.conversations removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dealloc {
	[_conversations release];
	[super dealloc];
}

@end
