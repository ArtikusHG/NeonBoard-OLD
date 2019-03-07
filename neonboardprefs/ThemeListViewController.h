#import <Preferences/PSListController.h>

@interface ThemeListViewController : PSViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSMutableArray *finalList;
@property (nonatomic, retain) NSMutableArray *selectedCells;
@property (nonatomic, retain) UITableView *table;

@end
