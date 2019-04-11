#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#include <AppSupport/CPDistributedMessagingCenter.h>

NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"];

@interface SBIconImageView : UIView {
  double _overlayAlpha;
}
- (id)_generateIconBasicOverlayImageForFormat:(int)fp8;
@end

@interface SBIcon : NSObject
- (id)applicationBundleID;
@end

@interface SBApplicationIcon : SBIcon
@end

@interface NCNotificationViewController : UIViewController
- (NSString *)sectionID;
- (id)notificationRequest;
@end

@interface UIView (Neon)
- (NSArray *)allSubviews;
@end

@interface PLPlatterHeaderContentView : UIView
- (void)setIcons:(NSArray *)icons;
@end

@interface SearchUIAppIconImage
- (NSString *)bundleIdentifier;
@end

@interface WGWidgetHostingViewController
- (NSString *)appBundleID;
@end

@interface WGWidgetListItemViewController
- (WGWidgetHostingViewController *)widgetHost;
@end

@interface MPCPlayerPath
+ (id)deviceActivePlayerPath;
+ (NSString *)bundleID;
@end

@interface MediaControlsHeaderView : UIView
- (void)setPlaceholderArtworkView:(UIImageView *)view;
- (UIImageView *)placeholderArtworkView;
@end

@interface PSTableCell
- (NSString *)getLazyIconID;
- (UIImage *)blankIcon;
@end

@interface NCNotificationRequestContentProvider
@property (nonatomic,readonly) UIImage *thumbnail;
@property (nonatomic,readonly) NSArray *icons;

- (NSString *)_appBundleIdentifer;
@end

// Custom class for methods that I need to call multiple times

@interface Neon : NSObject
+ (NSString *)filePathForBundleID:(NSString *)bundleID;
+ (BOOL)customIconExists:(NSString *)bundleID;
+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked origImage:(UIImage *)origImage;
+ (id)resizeImage:(UIImage *)image toSize:(int)size;
+ (UIImage *)maskImage:(UIImage *)toMaskImage withImage:(UIImage *)maskImage size:(int)size;
@end

@implementation Neon

NSArray *themes = nil;
UIImage *maskImage = nil;

+ (NSString *)device {
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return @"~ipad";
  return @"";
}

+ (int)imageSize {
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) return 78;
  return 60;
}

+ (NSString *)screenScale {
  if([UIScreen mainScreen].scale == 1.0f) return @"";
  if([UIScreen mainScreen].scale == 2.0f) return @"@2x";
  if([UIScreen mainScreen].scale == 3.0f) return @"@3x";
  return @"@2x";
}

+ (NSString *)filePathForBundleID:(NSString *)bundleID {
  if(![[prefs valueForKey:@"Themes enabled"] boolValue]) return @"";
  // Credit: Nick Frey for IconBundles source code, https://github.com/nickfrey/IconBundles
  // Hacked up by me to actually get the proper file path because my own thing wasn't really working...
  if(themes == nil) themes = [prefs objectForKey:@"selectedCells"];
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
      path = [themePath stringByAppendingString:@"/Bundles/com.apple.springboard/ClockIconBackgroundSquare~iphone.png"];
      if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil] && [UIScreen mainScreen].scale == 2.0) {
        path = [themePath stringByAppendingString:@"/Bundles/com.apple.springboard/ClockIconBackgroundSquare@2x.png"];
        if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return path;
      } else return path;
    }
  }
  return @"";
}

+ (BOOL)customIconExists:(NSString *)bundleID {
  if([self filePathForBundleID:bundleID].length != 0) return YES;
  return NO;
}

+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked origImage:(UIImage *)origImage {
  int size = (int)floorf(origImage.size.width);
  if(maskImage == nil) maskImage = [[[objc_getClass("SBIconImageView") alloc] init] _generateIconBasicOverlayImageForFormat:2];
  if(themes == nil) themes = [prefs objectForKey:@"selectedCells"];
  if(![[prefs valueForKey:@"Themes enabled"] boolValue] && ![[prefs valueForKey:@"Masks enabled"] boolValue]) return origImage;
  UIImage *finalImage = nil;
  NSString *path = nil;
  // go with themes
  if([[prefs valueForKey:@"Themes enabled"] boolValue]) {
    path = [self filePathForBundleID:bundleID];
    if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
      UIImage *image = [UIImage imageWithContentsOfFile:path];
      finalImage = [self resizeImage:image toSize:size];
    }
    if(!masked) return finalImage;
    if([[prefs valueForKey:@"Themes enabled"] boolValue] || [[prefs valueForKey:@"Masks enabled"] boolValue]) {
      if([[prefs valueForKey:@"Masks enabled"] boolValue]) {
        NSString *maskPath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"Masks"],[Neon device],[Neon screenScale]];
        UIImage *customMaskImage = [UIImage imageWithContentsOfFile:maskPath];
        finalImage = [self maskImage:finalImage withImage:customMaskImage size:size];
      } else finalImage = [self maskImage:finalImage withImage:maskImage size:size];
    }
  }
  return finalImage;
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

+ (id)resizeImage:(UIImage *)image toSize:(int)size {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(size,size), NO, [UIScreen mainScreen].scale);
  [image drawInRect:CGRectMake(0,0,size,size)];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return finalImage;
}

@end

// Actual hook


/*%hook SBApplicationIcon

- (UIImage *)generateIconImage:(int)format {
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  if(format == 5) return [Neon iconImageForBundleID:[self applicationBundleID] masked:YES origImage:%orig notification:YES];
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:YES origImage:%orig notification:NO];
}

- (UIImage *)getCachedIconImage:(int)fp8 {
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:YES origImage:%orig notification:NO];
}

- (UIImage *)getUnmaskedIconImage:(NSInteger)format {
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:NO origImage:%orig notification:NO];
}

%end

// Control center now playing icon

%hook MPCPlayerPath

NSString *globalBundleID = nil;

+(MPCPlayerPath *)pathWithRoute:(id)arg1 bundleID:(NSString *)bundleID playerID:(id)arg3 {
  // the cc shows the music icon on idle so lets set it to music if nothing is playing
  if(bundleID.length == 0) globalBundleID = @"com.apple.Music";
  else globalBundleID = [bundleID copy];
  return %orig;
}

%new
+ (NSString *)bundleID {
  return globalBundleID;
}

%end

%hook MediaControlsPanelViewController

- (MediaControlsHeaderView *)headerView {
  if(![Neon customIconExists:[objc_getClass("MPCPlayerPath") bundleID]]) return %orig;
  UIImage *icon = [Neon iconImageForBundleID:[objc_getClass("MPCPlayerPath") bundleID] masked:YES origImage:nil notification:NO];
  icon = [Neon resizeImage:icon toSize:29];
  UIImageView *customImageView = [%orig placeholderArtworkView];
  [customImageView setImage:icon];
  MediaControlsHeaderView *customHeaderView = %orig;
  [customHeaderView setPlaceholderArtworkView:customImageView];
  return customHeaderView;
}

%end

// Notifs, iOS 12

%hook NCNotificationViewController

%new
- (NSString *)sectionID {
  return [MSHookIvar<NSString *>([self notificationRequest], "_sectionIdentifier") copy];
}

%end

%hook PLPlatterHeaderContentView

- (void)setIcons:(NSArray *)icons {
  UIResponder *responder = self;
  NSString *bundleID = nil;
  while ([responder isKindOfClass:[UIView class]]) responder = [responder nextResponder];
  if([responder isKindOfClass:objc_getClass("NCNotificationViewController")]) {
    NCNotificationViewController *vc = (NCNotificationViewController *)responder;
    bundleID = [vc sectionID];
  } else if([responder isKindOfClass:objc_getClass("WGWidgetListItemViewController")]) {
    WGWidgetListItemViewController *vc = (WGWidgetListItemViewController *)responder;
    bundleID = [[vc widgetHost] appBundleID];
  } else {
    %orig;
    return;
  }
  if([Neon customIconExists:bundleID]) %orig(@[[Neon iconImageForBundleID:bundleID masked:YES origImage:nil notification:YES]]);
  else %orig;
}

%end

%hook NCShortLookView
- (void)setIcon:(UIImage *)icon {
  UIResponder *responder = self;
  NSString *bundleID = nil;
  while ([responder isKindOfClass:[UIView class]]) responder = [responder nextResponder];
  if([responder isKindOfClass:objc_getClass("NCNotificationViewController")]) {
    NCNotificationViewController *vc = (NCNotificationViewController *)responder;
    bundleID = [vc sectionID];
  } else {
    %orig;
    return;
  }
  if([Neon customIconExists:bundleID]) %orig([Neon iconImageForBundleID:bundleID masked:YES origImage:nil notification:YES]);
  else %orig;
}
%end

%hook SearchUIAppIconImage

- (UIImage *)generateImageWithFormat:(int)format {
  if(![Neon customIconExists:[self bundleIdentifier]]) return %orig;
  return [Neon iconImageForBundleID:[self bundleIdentifier] masked:YES origImage:%orig notification:NO];
}

%end*/

%hook UIImage

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(double)scale {
  if(![Neon customIconExists:bundleIdentifier]) return %orig;
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES origImage:%orig];
}

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format {
  if(![Neon customIconExists:bundleIdentifier]) return %orig;
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES origImage:%orig];
}

// Idk why I added this; it's an iOS 4/5 method.
+ (UIImage *)_applicationIconImageForBundleIdentifier:(id)bundleIdentifier roleIdentifier:(id)roleIdentifier format:(int)format scale:(float)scale {
  if(![Neon customIconExists:bundleIdentifier]) return %orig;
  return [Neon iconImageForBundleID:bundleIdentifier masked:YES origImage:%orig];
}

%end

%hook SBApplicationIcon

- (UIImage *)getUnmaskedIconImage:(NSInteger)format {
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:NO origImage:%orig];
}

%end

%hook APWUtil

+ (UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier withFormat:(int)format {
  if(![Neon customIconExists:bundleIdentifier]) return %orig;
  UIImage *unmaskedIcon = [Neon iconImageForBundleID:bundleIdentifier masked:NO origImage:%orig];
  // So. The Neon method above uses SBIconImageView to get the mask image...
  // Which is not possible due to this not being a SpringBoard class. It's from AppPredictionWidget.
  // So, err, we get a non-exsisting (blank) icon and mask the icon we have with it.
  // BIIIIIIIG TODO: CUSTOM MASKS.
  UIImage *maskImage = %orig(@"im.sure.this.bundle.id.doesnt.exist",format);
  return [Neon maskImage:unmaskedIcon withImage:maskImage size:%orig.size.width];
}

%end

// Clock icon

%hook SBClockApplicationIconImageView

- (id)contentsImage {
  if(![Neon customIconExists:@"com.apple.mobiletimer"]) return %orig;
  return [Neon iconImageForBundleID:@"com.apple.mobiletimer" masked:YES origImage:%orig];
}

- (id)_generateSquareContentsImage {
  if(![Neon customIconExists:@"com.apple.mobiletimer"]) return %orig;
  return [Neon iconImageForBundleID:@"com.apple.mobiletimer" masked:NO origImage:%orig];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if(![[prefs valueForKey:@"Themes enabled"] boolValue]) return %orig;
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

// Notifications

/*%hook PLPlatterHeaderContentView

- (void)setIcons:(NSArray *)icons {
  UIResponder *responder = self;
  NSString *bundleID = nil;
  while ([responder isKindOfClass:[UIView class]]) responder = [responder nextResponder];
  if([responder isKindOfClass:objc_getClass("NCNotificationViewController")]) {
    NCNotificationViewController *vc = (NCNotificationViewController *)responder;
    bundleID = [vc sectionID];
  } else if([responder isKindOfClass:objc_getClass("WGWidgetListItemViewController")]) {
    WGWidgetListItemViewController *vc = (WGWidgetListItemViewController *)responder;
    bundleID = [[vc widgetHost] appBundleID];
  } else {
    %orig;
    return;
  }
  UIImage *image = [UIImage imageWithContentsOfFile:[Neon filePathForBundleID:@"com.apple.Maps"]];
  UIImage *owo = icons[0];
  image = [Neon resizeImage:image toSize:owo.size.width];
  if(bundleID.length != 0 && [Neon customIconExists:bundleID]) %orig(@[image]);
  else %orig;
  %orig;
}

%end*/

// Notifications

%hook NCNotificationRequestContentProvider

NSCache *icons = nil;

// iOS 12
- (NSArray *)icons {
  if(![Neon customIconExists:[self _appBundleIdentifer]]) return %orig;
  UIImage *icon = [icons objectForKey:[self _appBundleIdentifer]];
  if(icon) return @[icon];
  return %orig;
}

// iOS 10 - 11
/*- (UIImage *)icon {
  if(![Neon customIconExists:[self _appBundleIdentifer]]) return %orig;
  UIImage *icon = [icons objectForKey:[self _appBundleIdentifer]];
  if(icon) return icon;
  return %orig;
}*/

- (instancetype)initWithNotificationRequest:(id)arg1 {
  // TODO: THE ICONS ARRAY DOESN'T EXIST ON iOS 10 & 11 SO PLEASE FIND AN ALTERNATIVE
  if(icons == nil) icons = [[NSCache alloc] init];
  if(![%orig _appBundleIdentifer] || ![Neon customIconExists:[%orig _appBundleIdentifer]] || [icons objectForKey:[%orig _appBundleIdentifer]]) return %orig;
  UIImage *icon = [Neon iconImageForBundleID:[%orig _appBundleIdentifer] masked:YES origImage:%orig.icons[0]];
  [icons setObject:icon forKey:[%orig _appBundleIdentifer]];
  return %orig;
}

%end

// Preferences
// AETIKSUDFHBND:SKA"L
// ALSKDJNKF
// akisjhdfghfdjkis
// sjdhfb
//kajshdf
//lckjvh/
//s][dpflkjhdsl;NeonBoard_FRAMEWORKSsd;l
//#ifndef f
//#define f value
//#endif]
// LOOkAT ME F ON ME YEAH
//ONLY MASK SHIT WITH BLANK ICON IF THERES NO MASKS ENABLED
// ALSO HOOK BLANK ICON TO RETURN MASKED!!!!
// YESSSSS PLZ

%hook PSTableCell

- (UIImage *)getLazyIcon {
  if(![Neon customIconExists:[self getLazyIconID]]) return %orig;
  UIImage *icon = [Neon resizeImage:[Neon iconImageForBundleID:[self getLazyIconID] masked:NO origImage:%orig] toSize:29];
  return [Neon maskImage:icon withImage:[self blankIcon] size:29];
}

%end

// Random options

%hook SBIconImageView

- (void)layoutSubviews {
  %orig;
  if([[prefs valueForKey:@"Masks enabled"] boolValue] && ![[prefs valueForKey:@"Disable dark overlay"] boolValue]) {
    NSString *device = [Neon device];
    NSString *scale = [Neon screenScale];
    CALayer *mask = [CALayer layer];
    NSString *maskPath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"Masks"],device,scale];
    UIImage *customMaskImage = [UIImage imageWithContentsOfFile:maskPath];
    mask.contents = (id)[customMaskImage CGImage];
    mask.frame = CGRectMake(0,0,62,62);
    MSHookIvar<UIImageView *>(self, "_overlayView").layer.mask = mask;
    MSHookIvar<UIImageView *>(self, "_overlayView").layer.masksToBounds = YES;
  }
}

- (id)initWithFrame:(CGRect)arg1 {
  if([[prefs valueForKey:@"Disable dark overlay"] boolValue]) {
    SBIconImageView *imAThief = %orig;
    MSHookIvar<double>(imAThief,"_overlayAlpha") = 0;
    return imAThief;
  }
  return %orig;
}

%end

%hook SBIconBadgeView

- (void)setAccessoryBrightness:(double)arg1 {
  if(![[prefs valueForKey:@"Disable dark overlay"] boolValue]) %orig;
}

%end

// Hide icon labels

%hook SBIconView

- (CGRect)_frameForLabel {
  if([[prefs objectForKey:@"Hide labels"] boolValue]) return CGRectNull;
  return %orig;
}

%end
