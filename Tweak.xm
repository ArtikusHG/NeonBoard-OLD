#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#include <AppSupport/CPDistributedMessagingCenter.h>

NSDictionary *prefs;

// Headers are a mess.

@interface SBIcon : NSObject
- (id)applicationBundleID;
@end

@interface SBApplicationIcon : SBIcon
- (UIImage *)getUnmaskedIconImage:(NSInteger)format;
@end

@interface UIView (Private)
- (NSArray *)allSubviews;
@end

@interface UIImage (Private)
- (UIImage *)_applicationIconImageForFormat:(int)format precomposed:(BOOL)precomposed scale:(double)scale;
- (UIImage *)_applicationIconImageForFormat:(int)format precomposed:(BOOL)precomposed;
@end

@interface NCNotificationRequestContentProvider
@property (nonatomic,readonly) UIImage *thumbnail;
@property (nonatomic,readonly) NSArray *icons;
- (NSString *)_appBundleIdentifer;
@end

@interface NSExtension : NSObject
@end

@interface WGWidgetInfo
@property (setter=_setIcon:,getter=_icon,nonatomic,retain) UIImage *icon;
- (NSString *)widgetIdentifier;
@end

// Custom class for methods that I need to call multiple times

@interface Neon : NSObject
+ (NSString *)filePathForBundleID:(NSString *)bundleID;
+ (BOOL)customIconExists:(NSString *)bundleID;
+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked format:(int)format;
+ (id)resizeImage:(UIImage *)image toSize:(int)size;
+ (UIImage *)maskImage:(UIImage *)toMaskImage withImage:(UIImage *)maskImage size:(int)size;
+ (UIImage *)customlyMaskedImageForImage:(UIImage *)image;
@end

@implementation Neon

NSArray *themes = nil;
NSCache *pathCache = nil;
NSCache *unmaskedIconCache = nil;

+ (NSString *)device {
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return @"~ipad";
  return @"";
}

+ (NSString *)screenScale {
  if([UIScreen mainScreen].scale == 1.0f) return @"";
  if([UIScreen mainScreen].scale == 2.0f) return @"@2x";
  if([UIScreen mainScreen].scale == 3.0f) return @"@3x";
  return @"@2x";
}

+ (NSString *)filePathForBundleID:(NSString *)bundleID {
  // Didn't wanna mess up the code so made a separate method managing cache too
  NSString *cachedPath = [pathCache objectForKey:bundleID];
  if(cachedPath.length != 0 && ![cachedPath isEqualToString:@"DOESNTEXIST"]) return cachedPath;
  else {
    NSString *path = [self generateFilePathForBundleID:bundleID];
    if(path.length != 0) [pathCache setObject:path forKey:bundleID];
    else [pathCache setObject:@"DOESNTEXIST" forKey:bundleID];
    return path;
  }
}

+ (NSString *)generateFilePathForBundleID:(NSString *)bundleID {
  // Credit: Nick Frey for IconBundles source code, https://github.com/nickfrey/IconBundles
  // Hacked up by me to actually get the proper file path because my own thing wasn't really working...
  CGFloat scale = [UIScreen mainScreen].scale;
  NSString *path = nil;
  if([bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    bundleID = @"clock";
  }
  NSMutableArray *potentialFilenames = [[NSMutableArray alloc] init];
  CGFloat displayScale = (scale > 0 ? scale : [UIScreen mainScreen].scale);
  while (displayScale >= 1.0) {
    NSMutableString *filename = [NSMutableString stringWithString:bundleID];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) [filename appendString:@"~ipad"];
    if (displayScale == 2.0) [filename appendString:@"@2x"];
    else if (displayScale == 3.0) [filename appendString:@"@3x"];
    [filename appendString:@".png"];
    [potentialFilenames addObject:filename];
    displayScale--;
  }
  // For more modern themes that use "bundleid-large.png"
  [potentialFilenames addObject:[bundleID stringByAppendingString:@"-large.png"]];
  // For weird themes that Anemone for some reason supports (not ~ipad@2x but @2x~ipad, ~iphone, etc)
  [potentialFilenames addObject:[bundleID stringByAppendingString:[NSString stringWithFormat:@"~iphone%@.png",[Neon screenScale]]]];
  [potentialFilenames addObject:[bundleID stringByAppendingString:[NSString stringWithFormat:@"%@~iphone.png",[Neon screenScale]]]];
  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) [potentialFilenames addObject:[bundleID stringByAppendingString:[NSString stringWithFormat:@"%@~iphone.png",[Neon screenScale]]]];
  for (NSString *theme in themes) {
    for (NSString *filename in potentialFilenames) {
      path = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles/%@",theme,filename];
      if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@",theme,filename];
      if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return path;
    }
    if([bundleID isEqualToString:@"clock"]) {
      NSString *themePath = [@"/Library/Themes/" stringByAppendingString:theme];
      if(![[NSFileManager defaultManager] fileExistsAtPath:themePath isDirectory:nil]) themePath = [themePath stringByAppendingString:@".theme"];
      path = [themePath stringByAppendingString:@"/Bundles/com.apple.springboard/"];
      NSMutableArray *potentialClockFilenames = [[NSMutableArray alloc] init];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare@2x.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~iphone.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare@2x~iphone.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~iphone@2x.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare@3x~iphone.png"];
      [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~iphone@3x.png"];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~ipad.png"];
        [potentialClockFilenames addObject:@"ClockIconBackgroundSquare@2x~ipad.png"];
        [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~ipad@2x.png"];
        [potentialClockFilenames addObject:@"ClockIconBackgroundSquare@3x~ipad.png"];
        [potentialClockFilenames addObject:@"ClockIconBackgroundSquare~ipad@3x.png"];
      }
      for (NSString *filename in potentialClockFilenames) {
        NSString *fullPath = [path stringByAppendingString:filename];
        if([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) return fullPath;
      }
    }
  }
  return @"";
}

+ (BOOL)customIconExists:(NSString *)bundleID {
  if([self filePathForBundleID:bundleID].length != 0) return YES;
  return NO;
}

+ (UIImage *)unmaskedIconImageForBundleID:(NSString *)bundleID {
  UIImage *finalImage = [unmaskedIconCache objectForKey:bundleID];
  if(finalImage) return finalImage;
  NSString *path = [self filePathForBundleID:bundleID];
  if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) finalImage = [UIImage imageWithContentsOfFile:path];
  if(finalImage) [unmaskedIconCache setObject:finalImage forKey:bundleID];
  return finalImage;
}

+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked format:(int)format {
  UIImage *finalImage = [self unmaskedIconImageForBundleID:bundleID];
  if(!masked) return finalImage;
  finalImage = [finalImage _applicationIconImageForFormat:format precomposed:YES scale:[UIScreen mainScreen].scale];
  return finalImage;
}

+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked origImage:(UIImage *)origImage {
  int size = (int)origImage.size.width;
  UIImage *finalImage = [self unmaskedIconImageForBundleID:bundleID];
  finalImage = [self resizeImage:finalImage toSize:size];
  if(!masked) return finalImage;
  if([[prefs valueForKey:@"kMasksEnabled"] boolValue]) {
    finalImage = [self customlyMaskedImageForImage:finalImage];
  } else finalImage = [self maskImage:finalImage withImage:origImage size:size];
  return finalImage;
}

+ (UIImage *)customlyMaskedImageForImage:(UIImage *)image {
  int size = (int)image.size.width;
  NSMutableArray *potentialFilenames = [[NSMutableArray alloc] init];
  NSString *maskPath = nil;
  [potentialFilenames addObject:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"kMask"],[Neon device],[Neon screenScale]]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"kMask"],[Neon screenScale],[Neon device]]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@.png",[prefs objectForKey:@"kMask"],[Neon device]]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@.png",[prefs objectForKey:@"kMask"],[Neon screenScale]]];
  for (NSString *path in potentialFilenames) {
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) maskPath = path;
  }
  if(!maskPath) return image;
  UIImage *customMaskImage = [UIImage imageWithContentsOfFile:maskPath];
  image = [self maskImage:image withImage:customMaskImage size:size];
  return image;
}

+ (UIImage *)maskImage:(UIImage *)toMaskImage withImage:(UIImage *)maskImage size:(int)size {
  CALayer *mask = [CALayer layer];
  mask.contents = (id)[maskImage CGImage];
  mask.frame = CGRectMake(0,0,size,size);
  CALayer *imageLayer = [CALayer layer];
  imageLayer.frame = CGRectMake(0,0,size,size);
  imageLayer.contents = (id)toMaskImage.CGImage;
  imageLayer.mask = mask;
  imageLayer.masksToBounds = YES;
  UIGraphicsBeginImageContextWithOptions(toMaskImage.size, NO, [UIScreen mainScreen].scale);
  [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return maskedImage;
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(int)size {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(size,size), NO, [UIScreen mainScreen].scale);
  [image drawInRect:CGRectMake(0,0,size,size)];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return finalImage;
}

@end

// Actual hook

%group Themes

%hook UIImage

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(double)scale {
  if(![Neon customIconExists:bundleIdentifier]) {
    if([[prefs objectForKey:@"kMasksEnabled"] boolValue] && /* temporary fix because that causes issues on 7 - 10 */ kCFCoreFoundationVersionNumber >= 1443.00) return [%orig _applicationIconImageForFormat:format precomposed:YES scale:scale];
    return %orig;
  }
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES format:format];
}

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format {
  if(![Neon customIconExists:bundleIdentifier]) {
    if([[prefs objectForKey:@"kMasksEnabled"] boolValue] && /* temporary fix because that causes issues on 7 - 10 */ kCFCoreFoundationVersionNumber >= 1443.00) return [%orig _applicationIconImageForFormat:format precomposed:YES];
    return %orig;
  }
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES format:format];
}

%end

%hook SBApplicationIcon

- (UIImage *)getUnmaskedIconImage:(NSInteger)format {
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:NO format:format];
}

%end

// Clock icon

%hook SBClockApplicationIconImageView

- (UIImage *)contentsImage {
  if(![Neon customIconExists:@"com.apple.mobiletimer"]) {
    if([[prefs objectForKey:@"kMasksEnabled"] boolValue]) return [Neon customlyMaskedImageForImage:%orig];
    return %orig;
  }
  return [Neon iconImageForBundleID:@"com.apple.mobiletimer" masked:YES origImage:%orig];
}

- (UIImage *)_generateSquareContentsImage {
  if(![Neon customIconExists:@"com.apple.mobiletimer"]) {
    if([[prefs objectForKey:@"kMasksEnabled"] boolValue]) return [Neon customlyMaskedImageForImage:%orig];
    return %orig;
  }
  return [Neon iconImageForBundleID:@"com.apple.mobiletimer" masked:YES origImage:%orig];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  if(themes == nil) themes = [prefs objectForKey:@"selectedCells"];
  NSDictionary *files = @{
    @"ClockIconSecondHand":@"seconds",
    @"ClockIconMinuteHand":@"minutes",
    @"ClockIconHourHand":@"hours",
    @"ClockIconBlackDot":@"blackDot",
    @"ClockIconRedDot":@"redDot"
  };
  for (NSString *theme in themes) {
    NSString *fullTheme = [@"/Library/Themes/" stringByAppendingString:theme];
    if(![[NSFileManager defaultManager] fileExistsAtPath:fullTheme isDirectory:nil]) fullTheme = [fullTheme stringByAppendingString:@".theme"];
    for (NSString *key in [files allKeys]) {
      NSString *path = [NSString stringWithFormat:@"%@/Bundles/com.apple.springboard/%@.png",fullTheme,key];
      if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *hookiVarName = [@"_" stringByAppendingString:[files objectForKey:key]];
        const char *chookIvarName = [hookiVarName cStringUsingEncoding:NSUTF8StringEncoding];
        MSHookIvar<CALayer *>(self, chookIvarName).contents = (id)[UIImage imageWithContentsOfFile:path].CGImage;
      }
    }
  }
  return self;
}

%end

// END THEMES GROUP

%end

// Notifications, disabled by default in settings cause it seems to drain battery

%group Notifications

%hook NCNotificationRequestContentProvider

// iOS 12
- (NSArray *)icons {
  if(![self _appBundleIdentifer] || ![Neon customIconExists:[self _appBundleIdentifer]]) return %orig;
  UIImage *icon = [Neon iconImageForBundleID:[self _appBundleIdentifer] masked:YES origImage:%orig[0]];
  return @[icon];
}

// iOS 10 - 11
- (UIImage *)icon {
  if(![self _appBundleIdentifer] || ![Neon customIconExists:[self _appBundleIdentifer]]) return %orig;
  UIImage *icon = [Neon iconImageForBundleID:[self _appBundleIdentifer] masked:YES origImage:%orig];
  return icon;
}

%end

%end

// Widget icons, also disabled by default because idk about its stability

%group Widgets

%hook WGWidgetInfo

- (UIImage *)_queue_iconWithFormat:(int)format forWidgetWithIdentifier:(NSString *)widgetIdentifier extension:(NSExtension *)extension {
  NSString *bundleIdentifier = [widgetIdentifier substringToIndex:[widgetIdentifier rangeOfString:@"." options:NSBackwardsSearch].location];
  if(![Neon customIconExists:bundleIdentifier]) {
    //if([[prefs objectForKey:@"kMasksEnabled"] boolValue]) return [%orig _applicationIconImageForFormat:format precomposed:NO scale:[UIScreen mainScreen].scale];
    return %orig;
  }
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES format:format];
}

- (UIImage *)_iconWithFormat:(int)format {
  NSString *bundleIdentifier = [[self widgetIdentifier] substringToIndex:[[self widgetIdentifier] rangeOfString:@"." options:NSBackwardsSearch].location];
  if(![Neon customIconExists:bundleIdentifier]) {
    if([[prefs objectForKey:@"kMasksEnabled"] boolValue]) return [Neon customlyMaskedImageForImage:%orig];
    else return %orig;
  }
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES format:format];
}

%end

%end

// Icon masks

@interface SBIconImageCrossfadeView : UIView
@end

CFURLRef CFBundleCopyResourceURL(CFBundleRef bundle, CFStringRef resourceName, CFStringRef resourceType, CFStringRef subDirName);

%group IconMasks

%hookf(CFURLRef, CFBundleCopyResourceURL, CFBundleRef bundle, CFStringRef resourceName, CFStringRef resourceType, CFStringRef subDirName) {
  NSString *id = (__bridge NSString *)CFBundleGetIdentifier(bundle);
  if([id isEqualToString:@"com.apple.mobileicons.framework"]) {
    NSString *resourceNameString = (__bridge NSString *)resourceName;
    NSString *resourceTypeString = (__bridge NSString *)resourceType;
    NSString *fullFilename = [NSString stringWithFormat:@"%@.%@",resourceNameString,resourceTypeString];
    NSString *fullPath = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework/%@",[prefs objectForKey:@"kMask"],fullFilename];
    if(![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) fullPath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/%@",[prefs objectForKey:@"kMask"],fullFilename];
    NSString *weirdPath = [NSString stringWithFormat:@"file://%@",fullPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
      CFURLRef customURL = CFURLCreateWithString(NULL, (__bridge CFStringRef)weirdPath, NULL);
      return customURL;
    }
  }
  return %orig;
}

%hook SBIconImageCrossfadeView

- (void)setMasksCorners:(BOOL)masksCorners {
  %orig(NO);
}

%end

// Turns out we don't need this one here anymore(?)

/*%hook SBIcon

+ (UIImage *)pooledIconImageForMappedIconImage:(UIImage *)mappedIconImage {
  NSString *device = [Neon device];
  NSString *scale = [Neon screenScale];
  NSString *maskPath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"Masks.0"],device,scale];
  return [Neon maskImage:%orig withImage:[UIImage imageWithContentsOfFile:maskPath] size:%orig.size.width];
}

%end*/

%end

// Temporary fix for the iOS 11+ animation bug with masks (creates another, smaller bug though)

%group iOS11AndLaterMasksHotfix

%hook SBIconImageCrossfadeView

NSString *globalMaskPath = nil;

- (instancetype)initWithFrame:(CGRect)frame {
  if([globalMaskPath isEqualToString:@"NOMASK"]) return %orig;
  self = %orig;
  NSString *device = [Neon device];
  NSString *scale = [Neon screenScale];
  NSMutableArray *potentialFilenames = [[NSMutableArray alloc] init];
  NSString *maskPath = nil;
  NSString *themePath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/",[prefs objectForKey:@"kMask"]];
  NSString *themeNoExtensionPath = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework/",[prefs objectForKey:@"kMask"]];
  // it's a mess, but i hope it works.
  [potentialFilenames addObject:@"AppIconMask.png"];
  [potentialFilenames addObject:[NSString stringWithFormat:@"AppIconMask%@%@.png",device,scale]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"AppIconMask%@%@.png",scale,device]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"AppIconMask~iphone%@.png",scale]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"AppIconMask%@~iphone.png",scale]];
  for (NSString *filename in potentialFilenames) {
    NSString *fullPath = [themePath stringByAppendingString:filename];
    NSString *fullNoExtensionPath = [themeNoExtensionPath stringByAppendingString:filename];
    if([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
      maskPath = fullPath;
      break;
    } else if([[NSFileManager defaultManager] fileExistsAtPath:fullNoExtensionPath isDirectory:nil]) {
      maskPath = fullNoExtensionPath;
      break;
    } else continue;
  }
  if(maskPath.length != 0) globalMaskPath = maskPath;
  else {
    globalMaskPath = @"NOMASK";
    return self;
  }
  CALayer *mask = [CALayer layer];
  UIImage *customMaskImage = [UIImage imageWithContentsOfFile:maskPath];
  mask.contents = (id)[customMaskImage CGImage];
  mask.frame = CGRectMake(0,0,60,60);
  self.layer.masksToBounds = YES;
  self.layer.mask = mask;
  return self;
}

%end

%end

// Random options

// Disable dark overlay

%group NoOverlay
%hook SBIconView
- (void)setHighlighted:(BOOL)isHighlighted { %orig(NO); }
%end
%end

// Hide icon labels

%group HideLabels
%hook SBIconView
- (CGRect)_frameForLabel {
  return CGRectNull;
}
%end
%end

// Hide dock background

%group NoDockBg
%hook SBDockView
- (void)setBackgroundAlpha:(double)setBackgroundAlpha { %orig(0); }
%end
%end

// Hide page dots

%group NoPageDots
%hook SBIconListPageControl
- (void)setHidden:(BOOL)isHidden { %orig(YES); }
%end
%end

// Hide folder icon background

@interface SBFolderIconBackgroundView : UIView
@end

%group NoFolderIconBg
%hook SBFolderIconBackgroundView
- (instancetype)initWithDefaultSize {
  self = %orig;
  self.hidden = YES;
  return self;
}
%end
%end

%ctor {
  prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"];
  if([[prefs valueForKey:@"kThemesEnabled"] boolValue]) {
    themes = [prefs objectForKey:@"selectedCells"];
    pathCache = [[NSCache alloc] init];
    unmaskedIconCache = [[NSCache alloc] init];
    %init(Themes);
    if([[prefs valueForKey:@"kNotifsEnabled"] boolValue]) %init(Notifications);
    if([[prefs valueForKey:@"kWidgetsEnabled"] boolValue]) %init(Widgets);
  }
  if([[prefs valueForKey:@"kMasksEnabled"] boolValue]) {
    %init(IconMasks);
    if(kCFCoreFoundationVersionNumber >= 1443.00) %init(iOS11AndLaterMasksHotfix);
  }
  if([[prefs valueForKey:@"kNoOverlay"] boolValue]) %init(NoOverlay);
  if([[prefs valueForKey:@"kHideLabels"] boolValue]) %init(HideLabels);
  if([[prefs valueForKey:@"kNoDockBg"] boolValue]) %init(NoDockBg);
  if([[prefs valueForKey:@"kNoPageDots"] boolValue]) %init(NoPageDots);
  if([[prefs valueForKey:@"kNoFolderIconBg"] boolValue]) %init(NoFolderIconBg);
}
