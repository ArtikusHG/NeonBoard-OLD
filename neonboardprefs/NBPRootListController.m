#include <spawn.h>
#include <signal.h>
#include "NBPRootListController.h"
#import "ThemeListViewController.h"
#import "ThemeSortViewController.h"
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation NBPRootListController

NSInteger scale;
NSString *device;

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (NSArray *)getMasksArray {
	NSArray *masks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil];
	NSMutableArray *mutableMasks = [[NSMutableArray alloc] init];
	for (NSString *mask in masks) {
		if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework",mask] isDirectory:nil]) {
			[mutableMasks addObject:[mask stringByReplacingOccurrencesOfString:@".theme" withString:@""]];
		}
	}
	return [mutableMasks copy];
}

- (void)reloadSpringboard {
	pid_t pid;
	int status;
	const char *argv[] = {"killall", "SpringBoard", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);
}

- (void)twitter {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/ArtikusHG"] options:@{} completionHandler:nil];
}

- (void)github {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/ArtikusHG"] options:@{} completionHandler:nil];
}

- (void)soundcloud {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://soundcloud.com/ArtikusHG"] options:@{} completionHandler:nil];
}

// thanks Julioverne for opensourcing his tweaks :p
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
	[dict setObject:value forKey:[specifier propertyForKey:@"key"]];
	[dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
	return dict[[specifier propertyForKey:@"key"]]?:NO;
}

@end
