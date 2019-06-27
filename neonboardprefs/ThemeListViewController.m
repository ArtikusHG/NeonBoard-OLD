#include "NBPRootListController.h"
#include "ThemeListViewController.h"
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation ThemeListViewController

@synthesize finalList;
@synthesize selectedCells;
@synthesize table;

- (void)viewDidLoad {
	[super viewDidLoad];
	selectedCells = [[NSMutableArray alloc] init];
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
	NSArray *arr = [dict objectForKey:@"selectedCells"];
	if([dict objectForKey:@"selectedCells"] != nil) selectedCells = [arr mutableCopy];
	NSArray *titles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil];
	NSMutableArray *mutableThemes = [[NSMutableArray alloc] init];
	for (NSString *object in titles) {
		if(![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework",object] isDirectory:nil]) {
			[mutableThemes addObject:[object stringByReplacingOccurrencesOfString:@".theme" withString:@""]];
		}
	}
	finalList = mutableThemes;
	table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
	[table setDataSource:self];
	[table setDelegate:self];
  [table setAllowsSelectionDuringEditing:YES];
	if ([self respondsToSelector:@selector(setView:)]) [self setView:table];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return finalList.count;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"cell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
	cell.textLabel.text = [finalList objectAtIndex:indexPath.row];
	// warning: super ugly line of code
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
	NSArray *arr = [dict objectForKey:@"selectedCells"];
	if([arr containsObject:cell.textLabel.text]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if([selectedCells containsObject:[finalList objectAtIndex:indexPath.row]]) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[selectedCells removeObject:[finalList objectAtIndex:indexPath.row]];
		[self writeData];
		return;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[selectedCells addObject:[finalList objectAtIndex:indexPath.row]];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	[self writeData];
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)writeData {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
	[dict setObject:selectedCells forKey:@"selectedCells"];
	[dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

@end
