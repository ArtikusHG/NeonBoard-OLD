#include <spawn.h>
#include <signal.h>
#include "NBPRootListController.h"
#import "ThemeListViewController.h"
#import "ThemeSortViewController.h"
#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

// Custom banner cell

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
@end

@interface BannerCell : PSTableCell <PreferencesTableCustomView> {
	UILabel *topLabel;
}
@end

@implementation BannerCell
- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
	if (self) {
		[self setBackgroundColor:[UIColor clearColor]];
		topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.bounds.size.width,60)];
		[topLabel setBackgroundColor:[UIColor clearColor]];
		[topLabel setText:@"NeonBoard"];
		[topLabel setFont:[UIFont boldSystemFontOfSize:40]];
		[topLabel setShadowColor:[UIColor whiteColor]];
		[topLabel setShadowOffset:CGSizeMake(0,0)];
		[self addSubview:topLabel];
	}
	return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	return 60.f;
}
@end

@implementation NBPRootListController

NSInteger scale;
NSString *device;

- (NSArray *)specifiers {
	if (!_specifiers) {
		// Initialize and assign some variables
		scale = (NSInteger)floor([UIScreen mainScreen].scale);
	 	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) device = @"~ipad";
		else device = @"";
		// Create array with list of files in /Library/Themes
		NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil];
		// Initialize an empty mutable array
		NSMutableArray *mutableMasks = [[NSMutableArray alloc] init];
		// For loop to check if theme contains mask
		for (NSString *object in array) {
			// If check for the file that appears to be the mask file
			if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework/AppIconMask@%ldx%@.png",object,(long)scale,device] isDirectory:nil]) {
				// If true, add the theme to the list of masks
				[mutableMasks addObject:[object stringByReplacingOccurrencesOfString:@".theme" withString:@""]];
			}
		}
		// Since the specifier requires a non-mutable array, create a non-mutable copy of the array
		NSArray *finalArray = [mutableMasks copy];
		// Specifiers
		// Top banner
		//PSSpecifier *banner = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		//[banner setProperty:@"BannerCell" forKey:@"footerCellClass"];
		// Enabled/disabled toggle (themes)
		PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Themes enabled" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
		// Enabled/disabled toggle (masks)
		PSSpecifier *masksEnabled = [PSSpecifier preferenceSpecifierNamed:@"Masks enabled" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:)detail:nil cell:PSSwitchCell edit:nil];
		// Enabled/disabled toggle (hide labels)
		PSSpecifier *labelsHidden = [PSSpecifier preferenceSpecifierNamed:@"Hide labels" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:)detail:nil cell:PSSwitchCell edit:nil];
		// Enabled/disabled toggle (hide dark icon overlay)
		PSSpecifier *disableOverlay = [PSSpecifier preferenceSpecifierNamed:@"Disable dark overlay" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
		// Link to ThemeListViewController
		PSSpecifier *themes = [PSSpecifier preferenceSpecifierNamed:@"Themes" target:self set:NULL get:NULL detail:NSClassFromString(@"ThemeListViewController") cell:PSLinkCell edit:nil];
		[themes setProperty:@YES forKey:@"enabled"];
		// Link to ThemeSortViewController
		PSSpecifier *sortThemes = [PSSpecifier preferenceSpecifierNamed:@"Sort themes" target:self set:NULL get:NULL detail:NSClassFromString(@"ThemeSortViewController") cell:PSLinkCell edit:nil];
		[sortThemes setProperty:@YES forKey:@"enabled"];
		// List of masks
		PSSpecifier *masks = [PSSpecifier preferenceSpecifierNamed:@"Masks" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NSClassFromString(@"PSListItemsController") cell:PSLinkListCell edit:Nil];
		[masks setProperty:@YES forKey:@"enabled"];
		[masks setProperty:@"0" forKey:@"default"];
		masks.values = finalArray;
		masks.titleDictionary = [NSDictionary dictionaryWithObjects:finalArray forKeys:masks.values];
		masks.shortTitleDictionary = [NSDictionary dictionaryWithObjects:finalArray forKeys:masks.values];
		[masks setProperty:@"kListValue" forKey:@"mask"];
		// Respring button
		PSSpecifier *respring = [PSSpecifier preferenceSpecifierNamed:@"Respring" target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
		[respring setProperty:@YES forKey:@"enabled"];
		respring->action = @selector(reloadSpringboard);
		// PSGroupCell specifiers
		PSSpecifier *enableThemes = [PSSpecifier preferenceSpecifierNamed:@"Enable themes" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *enableMasks = [PSSpecifier preferenceSpecifierNamed:@"Enable masks" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *disableDarkOverlay = [PSSpecifier preferenceSpecifierNamed:@"Disable dark icon overlay" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *hideLabels = [PSSpecifier preferenceSpecifierNamed:@"Hide icon labels" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *themesGroup = [PSSpecifier preferenceSpecifierNamed:@"Select themes" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *sortGroup = [PSSpecifier preferenceSpecifierNamed:@"Sort themes" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *masksGroup = [PSSpecifier preferenceSpecifierNamed:@"Select masks (beta)" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *respringGroup = [PSSpecifier preferenceSpecifierNamed:@"Respring to apply changes" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		PSSpecifier *followGroup = [PSSpecifier preferenceSpecifierNamed:@"Follow me" target:self set:NULL get:NULL detail:nil cell:PSGroupCell edit:nil];
		// Social links
		PSSpecifier *twitter = [PSSpecifier preferenceSpecifierNamed:@"Twitter" target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
		[twitter setProperty:@YES forKey:@"enabled"];
		twitter->action = @selector(twitter);
		PSSpecifier *github = [PSSpecifier preferenceSpecifierNamed:@"GitHub (the source code's there!)" target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
		[github setProperty:@YES forKey:@"enabled"];
		github->action = @selector(github);
		PSSpecifier *soundcloud = [PSSpecifier preferenceSpecifierNamed:@"SoundCloud (I make trash music)" target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
		[soundcloud setProperty:@YES forKey:@"enabled"];
		soundcloud->action = @selector(soundcloud);
		// Set the _specifiers array to have the specifiers in the correct order
		//_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	  _specifiers = [NSMutableArray arrayWithObjects:enableThemes,enabled,enableMasks,masksEnabled,disableDarkOverlay,disableOverlay,hideLabels,labelsHidden,themesGroup,themes,sortGroup,sortThemes,masksGroup,masks,respringGroup,respring,followGroup,twitter,github,soundcloud,nil];
		/*[_specifiers addObject:enableThemes];
		[_specifiers addObject:enabled];
		[_specifiers addObject:enableMasks];
		[_specifiers addObject:masksEnabled];
		[_specifiers addObject:disableDarkOverlay];
		[_specifiers addObject:disableOverlay];
		[_specifiers addObject:themesGroup];
		[_specifiers addObject:themes];
		[_specifiers addObject:sortGroup];
		[_specifiers addObject:sortThemes];
		[_specifiers addObject:masksGroup];
		[_specifiers addObject:masks];
		[_specifiers addObject:respringGroup];
		[_specifiers addObject:respring];
		[_specifiers addObject:followGroup];
		[_specifiers addObject:twitter];
		[_specifiers addObject:github];
		[_specifiers addObject:soundcloud];*/
	}
	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	// Copypasta from some Julioverne tweak source code (thanks!)
	// Basically this initializes a mutable dictionary, sets a value in it and writes it to the plist
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
	[dict setObject:value forKey:[specifier identifier]];
	[dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	// Another copypasta from some Julioverne tweak source code (thanks!)
	// Basically this initializes a dictionary and returns a value of it
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings];
	return dict[[specifier identifier]]?:[[specifier properties] objectForKey:@"default"];
}

- (void)reloadSpringboard {
	// I wanted to add a non-respring method to apply themes by copypasting the Anemone source code here
	// But, it didn't work, so guess I'll stick to  a respring for now :/
	// If NeonBoard ever gets popular (bet it won't) I'll actually implement a non-respring icon refresh :P
	pid_t pid;
	int status;
	const char *argv[] = {"killall", "SpringBoard", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);
}

- (void)twitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/artikus_hg"]];
}

- (void)github {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/ArtikusHG"]];
}

- (void)soundcloud {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://soundcloud.com/ArtikusHG"]];
}

@end
