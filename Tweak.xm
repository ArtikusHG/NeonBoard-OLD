#import <objc/runtime.h>

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

@interface MPCPlayerPath
- (NSString *)bundleID;
@end

// Custom class for methods that I need to call multiple times

@interface Neon : NSObject
+ (UIImage *)maskImage:(UIImage *)toMaskImage withImage:(UIImage *)maskImage notif:(BOOL)notif;
+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked origImage:(UIImage *)origImage notification:(BOOL)notif;
+ (id)resizeImage:(UIImage *)image notif:(BOOL)notif;
+ (BOOL)customIconExists:(NSString *)bundleID;
@end

@implementation Neon

id maskImage = nil;
NSArray *themes = nil;

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
  else if([UIScreen mainScreen].scale == 2.0f) return @"@2x";
  else return @"@3x";
}

+ (BOOL)customIconExists:(NSString *)bundleID {
  NSString *device = [Neon device];
  NSString *scale = [Neon screenScale];
  NSString *path = nil;
  if([[prefs valueForKey:@"Themes enabled"] boolValue]) {
    for(NSString *theme in [prefs objectForKey:@"selectedCells"]) {
      //path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@%@%@.png",theme,bundleID,device,scale];
      //if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return YES;
      path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@%@%@.png",theme,bundleID,device,scale];
      if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return YES;
      else {
        path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@%@.png",theme,bundleID,device];
        if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return YES;
        else {
          path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@-large.png",theme,bundleID];
          if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) return YES;
        }
      }
    }
  }
  return NO;
}

+ (UIImage *)iconImageForBundleID:(NSString *)bundleID masked:(BOOL)masked origImage:(UIImage *)origImage notification:(BOOL)notif {
  NSString *scale = [Neon screenScale];
  if(maskImage == nil) {
    maskImage = [[[objc_getClass("SBIconImageView") alloc] init] _generateIconBasicOverlayImageForFormat:2];
  }
  if(themes == nil) {
    themes = [prefs objectForKey:@"selectedCells"];
  }
  if(![[prefs valueForKey:@"Themes enabled"] boolValue] && ![[prefs valueForKey:@"Masks enabled"] boolValue]) return origImage;
  UIImage *finalImage = origImage;
  NSString *path = nil;
  NSString *device = [Neon device];
  // go with themes
  if([[prefs valueForKey:@"Themes enabled"] boolValue]) {
    for(NSString *theme in themes) {
      path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@%@%@.png",theme,bundleID,device,scale];
      if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) break;
      else {
        path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@%@.png",theme,bundleID,device];
        if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) break;
        else {
          path = [NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@-large.png",theme,bundleID];
          if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) break;
        }
      }
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
      UIImage *image = [UIImage imageWithContentsOfFile:path];
      finalImage = [self resizeImage:image notif:notif];
    }
    if(!masked) return finalImage;
    if([[prefs valueForKey:@"Themes enabled"] boolValue] || [[prefs valueForKey:@"Masks enabled"] boolValue]) {
      if([[prefs valueForKey:@"Masks enabled"] boolValue]) {
        NSString *maskPath = [NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png",[prefs objectForKey:@"Masks"],device,scale];
        UIImage *customMaskImage = [UIImage imageWithContentsOfFile:maskPath];
        finalImage = [self maskImage:finalImage withImage:customMaskImage notif:notif];
      } else finalImage = [self maskImage:finalImage withImage:maskImage notif:notif];
    }
  }
  return finalImage;
}

+ (UIImage *)maskImage:(UIImage *)toMaskImage withImage:(UIImage *)maskImage notif:(BOOL)notif {
  int size;
  if(notif) size = 20;
  else size = [Neon imageSize];
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

+ (id)resizeImage:(UIImage *)image notif:(BOOL)notif {
  int size;
  if(notif) size = 20;
  else size = [Neon imageSize];
  UIImage *finalImage;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(size,size), NO, [UIScreen mainScreen].scale);
  [image drawInRect:CGRectMake(0,0,size,size)];
  finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return finalImage;
}

@end

// Actual hook
// Replaces homescreen & app switcher icons on iOS 10 - 12, notification icons on iOS 7-9

%hook SBApplicationIcon

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
  %log;
  if(![Neon customIconExists:[self applicationBundleID]]) return %orig;
  return [Neon iconImageForBundleID:[self applicationBundleID] masked:NO origImage:%orig notification:NO];
}

%end

// Control center now playing icon

/*%hook MediaControlsHeaderView
// should work in theory but doesnt inject :/
- (void)setPlayerPath:(MPCPlayerPath *)playerPath {
  %log;
  %orig;
  if ([Neon customIconExists:[playerPath bundleID]]) MSHookIvar<UIImageView *>(self, "placeholderArtworkView") = [[UIImageView alloc] initWithImage:[Neon iconImageForBundleID:[playerPath bundleID] masked:YES origImage:nil notification:NO]];
}

%end*/

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

-(CGRect)_frameForLabel {
  if([[prefs objectForKey:@"Hide labels"] boolValue]) return CGRectNull;
  return %orig;
}

%end
