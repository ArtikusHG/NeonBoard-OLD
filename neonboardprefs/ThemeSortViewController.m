#include "NBPRootListController.h"
#include "ThemeSortViewController.h"
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation ThemeSortViewController

@synthesize themesList;

- (void)viewDidLoad {
  [super viewDidLoad];
	themesList = [[NSMutableArray alloc] init];
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
	NSArray *arr = [dict objectForKey:@"selectedCells"];
	if([dict objectForKey:@"selectedCells"] != nil) themesList = [arr mutableCopy];
  NSMutableDictionary *themesDict = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
  for (NSString *theme in themesList) {
    if(![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@",theme] isDirectory:nil] && ![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme",theme] isDirectory:nil]) {
      [themesList removeObject:theme];
      [themesDict setObject:themesList forKey:@"selectedCells"];
      [themesDict writeToFile:@PLIST_PATH_Settings atomically:YES];
    }
  }
	UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
	[table setDataSource:self];
	[table setDelegate:self];
	[table setEditing:YES];
	if ([self respondsToSelector:@selector(setView:)]) [self setView:table];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return themesList.count;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"cell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
	cell.textLabel.text = [themesList objectAtIndex:indexPath.row];
	return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  NSUInteger fromIndex = [fromIndexPath row];
  NSUInteger toIndex = [toIndexPath row];
  if (fromIndex == toIndex) return;
	NSString *theme = [themesList objectAtIndex:fromIndex];
  [themesList removeObjectAtIndex:fromIndex];
  [themesList insertObject:theme atIndex:toIndex];
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
	[dict setObject:themesList forKey:@"selectedCells"];
	[dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

@end
