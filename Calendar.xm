// Anemone's calendar icon theming implementation with some minor changes to make it work with NeonBoard and ARC
// Original code taken from: https://github.com/AnemoneTeam/Anemone-OSS

#import "UIColor+HTMLColors.h"

@interface SBCalendarApplicationIcon : NSObject
- (UIFont *)numberFont;
- (UIColor *)colorForDayOfWeek;
- (void)drawTextIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base;
@end

static NSDictionary *dateSettings, *daySettings;
static bool calendarSettingsLoaded = NO;

static CGFloat dateXoffset = 0.0f;
static CGFloat dateYoffset = 0.0f;
static CGFloat dateShadowXoffset = 0.0f;
static CGFloat dateShadowYoffset = 0.0f;
static CGFloat dateShadowBlurRadius = 0.0f;
static UIColor *dateTextColor = nil;
static NSString *dateTextCase = nil;
static UIColor *dateShadowColor = nil;

static NSString *dayFont = nil;
static CGFloat dayFontSize = 10.0f;
static CGFloat dayXoffset = 0.0f;
static CGFloat dayYoffset = 0.0f;
static CGFloat dayShadowXoffset = 0.0f;
static CGFloat dayShadowYoffset = 0.0f;
static CGFloat dayShadowBlurRadius = 0.0f;
static NSString *dayTextCase = nil;
static UIColor *dayShadowColor = nil;

static NSMutableArray *themesToShame = nil;

static void getCalendarSettings(){
	if (calendarSettingsLoaded) return;
	calendarSettingsLoaded = YES;
	NSArray *themes = [[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"] objectForKey:@"selectedCells"];

	for (NSString *theme in themes) {
		NSString *themePath = [@"/Library/Themes/" stringByAppendingString:theme];
		if(![[NSFileManager defaultManager] fileExistsAtPath:themePath isDirectory:nil]) themePath = [themePath stringByAppendingString:@".theme"];
		NSString *path = [NSString stringWithFormat:@"%@/Info.plist",themePath];
		NSLog(@"%@",path);
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
		if (dateSettings == nil)
		{
			dateSettings = themeDict[@"CalendarIconDateSettings"];
		}
		if (daySettings == nil){
			daySettings = themeDict[@"CalendarIconDaySettings"];
		}
		if (!(dateSettings == nil || [dateSettings isKindOfClass:[NSDictionary class]]) || !(daySettings == nil || [daySettings isKindOfClass:[NSDictionary class]])){
			dateSettings = nil;
			daySettings = nil;

			if (themesToShame == nil){
				themesToShame = [[NSMutableArray alloc] init];
			}
			[themesToShame addObject:theme];
		}
	}
}

static void loadCalendarSettings(){
	if (calendarSettingsLoaded)
		return;
	getCalendarSettings();

	dateXoffset = 0.0f;
	dateYoffset = 0.0f;
	dateShadowXoffset = 0.0f;
	dateShadowYoffset = 0.0f;
	dateShadowBlurRadius = 0.0f;
	dateTextColor = nil;
	dateShadowColor = nil;
	dateTextCase = nil;

	dayFont = nil;
	dayFontSize = 10.0f;
	dayXoffset = 0.0f;
	dayYoffset = 0.0f;
	dayShadowXoffset = 0.0f;
	dayShadowYoffset = 0.0f;
	dayShadowBlurRadius = 0.0f;
	dayShadowColor = nil;
	dayTextCase = nil;

	dateTextColor = [UIColor blackColor];
	dateShadowColor = [UIColor clearColor];

	dayFont = @"HelveticaNeue";
	if (kCFCoreFoundationVersionNumber > 1240)
		dayFont = @".SFUIText-Regular";
	if (kCFCoreFoundationVersionNumber > 1333)
		dayFont = @".SFUIText";
	dayShadowColor = [UIColor clearColor];

	if ([dateSettings objectForKey:@"TextXoffset"])
		dateXoffset = [[dateSettings objectForKey:@"TextXoffset"] floatValue];
	if ([dateSettings objectForKey:@"TextYoffset"])
		dateYoffset = [[dateSettings objectForKey:@"TextYoffset"] floatValue];
	if ([dateSettings objectForKey:@"TextColor"])
		dateTextColor = [UIColor anem_colorWithCSS:[dateSettings objectForKey:@"TextColor"]];
	if ([dateSettings objectForKey:@"TextCase"])
		dateTextCase = [[dateSettings objectForKey:@"TextCase"] lowercaseString];
	if ([dateSettings objectForKey:@"ShadowXoffset"])
		dateShadowXoffset = [[dateSettings objectForKey:@"ShadowXoffset"] floatValue];
	if ([dateSettings objectForKey:@"ShadowYoffset"])
		dateShadowYoffset = [[dateSettings objectForKey:@"ShadowYoffset"] floatValue];
	if ([dateSettings objectForKey:@"ShadowBlurRadius"])
		dateShadowBlurRadius = [[dateSettings objectForKey:@"ShadowBlurRadius"] floatValue];
	if ([dateSettings objectForKey:@"ShadowColor"])
		dateShadowColor = [UIColor anem_colorWithCSS:[dateSettings objectForKey:@"ShadowColor"]];

	if ([daySettings objectForKey:@"FontName"])
		dayFont = [daySettings objectForKey:@"FontName"];
	if ([daySettings objectForKey:@"FontSize"])
		dayFontSize = [[daySettings objectForKey:@"FontSize"] floatValue];
	if ([daySettings objectForKey:@"TextCase"])
		dayTextCase = [[daySettings objectForKey:@"TextCase"] lowercaseString];
	if ([daySettings objectForKey:@"TextXoffset"])
		dayXoffset = [[daySettings objectForKey:@"TextXoffset"] floatValue];
	if ([daySettings objectForKey:@"TextYoffset"])
		dayYoffset = [[daySettings objectForKey:@"TextYoffset"] floatValue];
	if ([daySettings objectForKey:@"ShadowXoffset"])
		dayShadowXoffset = [[daySettings objectForKey:@"ShadowXoffset"] floatValue];
	if ([daySettings objectForKey:@"ShadowYoffset"])
		dayShadowYoffset = [[daySettings objectForKey:@"ShadowYoffset"] floatValue];
	if ([daySettings objectForKey:@"ShadowBlurRadius"])
		dayShadowBlurRadius = [[daySettings objectForKey:@"ShadowBlurRadius"] floatValue];
	if ([daySettings objectForKey:@"ShadowColor"])
		dayShadowColor = [UIColor anem_colorWithCSS:[daySettings objectForKey:@"ShadowColor"]];

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		dateYoffset+=14.0f;
		dayYoffset+=8.0f;
	} else{
		dateYoffset+=12.0f;
		dayYoffset+=6.0f;
	}
}

%group Calendar

%hook SBCalendarApplicationIcon
- (UIImage *)_compositedIconImageForFormat:(int)format withBaseImageProvider:(UIImage *(^)())imageProvider {
	UIImage *baseImage = imageProvider();
	UIGraphicsBeginImageContextWithOptions(baseImage.size, NO, baseImage.scale);
	[self drawTextIntoCurrentContextWithImageSize:baseImage.size iconBase:baseImage];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (void)_drawIconIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base {
	[self drawTextIntoCurrentContextWithImageSize:imageSize iconBase:base];
}

%new;
- (void)drawTextIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base {
	loadCalendarSettings();

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	if (ctx == nil)
		return;
	[base drawInRect:CGRectMake(0,0,imageSize.width,imageSize.height)];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setLocale:[NSLocale currentLocale]];

	NSString *dateFont = @".SFUIDisplay-Ultralight";
	CGFloat dateFontSize = 39.5;
	if ([self respondsToSelector:@selector(numberFont)]){
		dateFont = [[self numberFont] fontName];
		dateFontSize = [[self numberFont] pointSize];
	}
	if ([dateSettings objectForKey:@"FontName"])
		dateFont = [dateSettings objectForKey:@"FontName"];
	if ([dateSettings objectForKey:@"FontSize"])
		dateFontSize = [[dateSettings objectForKey:@"FontSize"] floatValue];

	NSDate *date = [NSDate date];
	[dateFormatter setDateFormat:@"d"];
	NSString *day = [dateFormatter stringFromDate:date];

	if ([dateTextCase isEqualToString:@"lowercase"])
		day = [day lowercaseString];
	else if ([dateTextCase isEqualToString:@"uppercase"])
		day = [day uppercaseString];

	UIFont *numberFont = [UIFont fontWithName:dateFont size:dateFontSize];
	CGSize size = CGSizeZero;
	if (!numberFont) numberFont = [UIFont systemFontOfSize:dateFontSize];
	size = [day sizeWithAttributes:@{NSFontAttributeName:numberFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dateShadowXoffset,dateShadowYoffset), dateShadowBlurRadius, dateShadowColor.CGColor);
	CGContextSetAlpha(ctx, CGColorGetAlpha(dateTextColor.CGColor));
	[day drawAtPoint:CGPointMake(dateXoffset + ((imageSize.width-size.width)/2.0f),dateYoffset) withAttributes:@{NSFontAttributeName:numberFont, NSForegroundColorAttributeName:dateTextColor}];

	UIColor *dayTextColor = [UIColor redColor];
	if ([self respondsToSelector:@selector(colorForDayOfWeek)])
		dayTextColor = [self colorForDayOfWeek];
	if ([daySettings objectForKey:@"TextColor"])
		dayTextColor = [UIColor anem_colorWithCSS:[daySettings objectForKey:@"TextColor"]];

	[dateFormatter setDateFormat:@"EEEE"];
	NSString *dayOfWeek = [dateFormatter stringFromDate:date];

	if ([dayTextCase isEqualToString:@"lowercase"])
		dayOfWeek = [dayOfWeek lowercaseString];
	else if ([dayTextCase isEqualToString:@"uppercase"])
		dayOfWeek = [dayOfWeek uppercaseString];

	UIFont *dayOfWeekFont = [UIFont fontWithName:dayFont size:dayFontSize];
	if (!dayOfWeekFont) dayOfWeekFont = [UIFont systemFontOfSize:dayFontSize];
	size = [dayOfWeek sizeWithAttributes:@{NSFontAttributeName:dayOfWeekFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dayShadowXoffset,dayShadowYoffset), dayShadowBlurRadius, dayShadowColor.CGColor);

	CGContextSetAlpha(ctx, CGColorGetAlpha(dayTextColor.CGColor));
	[dayOfWeek drawAtPoint:CGPointMake(dayXoffset + ((imageSize.width-size.width)/2.0f),dayYoffset) withAttributes:@{NSFontAttributeName:dayOfWeekFont, NSForegroundColorAttributeName:dayTextColor}];
}
%end

%end

%ctor {
	if([[[[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"] objectForKey:@"kAdvancedCalendar"] boolValue]) %init(Calendar)
}
