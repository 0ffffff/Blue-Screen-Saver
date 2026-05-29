//
//  SCView.m
//  SC
//
//  Created by Simon Fransson on 2010-05-03.
//  Copyright (c) 2010, Hobo Code. All rights reserved.
//

#import "BSODSaverView.h"
#import "LegacyHostLifecycle.h"

#define DEFAULT_CRASH_TYPE  0.5
#define DEFAULT_FATALITY    0.5
#define DEFAULT_FONT_SIZE   15.0
#define PREVIEW_FONT_SIZE   6.0

@interface BSODSaverView ()
@property (nonatomic, assign) BOOL isAnimatingInternal;
@property (nonatomic, strong) LegacyHostLifecycle *hostLifecycle;
- (void)loadFontWithName:(NSString *)fontName inBundle:(NSBundle *)bundle;
- (void)configureContentFromDefaults;
@end

@implementation BSODSaverView

NSString *const kExternalURL = @"http://www.github.com/dessibelle/Blue-Screen-Saver";

+ (NSString *)moduleName
{
    return [[NSBundle bundleForClass:self] bundleIdentifier];
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        NSString *moduleName = [[self class] moduleName];
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:moduleName];

        [defaults registerDefaults:@{
            @"CrashType": @(DEFAULT_CRASH_TYPE),
            @"Fatality": @(DEFAULT_FATALITY),
            @"FontSize": @(DEFAULT_FONT_SIZE),
        }];

        self.defaults = defaults;
        self.backgroundColor = [NSColor colorWithCalibratedRed:(1.0/255.0) green:(2.0/255.0) blue:(172.0/255.0) alpha:1.0];
        self.captionBackgroundColor = [NSColor colorWithCalibratedRed:(169.0/255.0) green:(170.0/255.0) blue:(174.0/255.0) alpha:1.0];
        self.hasUnderscoreSuffix = NO;
        self.isAnimatingInternal = NO;

        [self setAnimationTimeInterval:1 / 1.5];

        NSBundle *screenSaverBundle = [NSBundle bundleForClass:[self class]];
        [self loadFontWithName:@"FixedsysTTF" inBundle:screenSaverBundle];
        [self loadFontWithName:@"LucidaConsole" inBundle:screenSaverBundle];

        [self configureContentFromDefaults];

        self.hostLifecycle = [[LegacyHostLifecycle alloc] initWithSaverView:self isPreview:isPreview];
        [self.hostLifecycle startMonitoring];
    }

    return self;
}

- (void)dealloc
{
    [self.hostLifecycle stopMonitoring];
}

- (void)configureContentFromDefaults
{
    srand48((long)arc4random());

    double fatal_rand = drand48() - 0.5 + [self.defaults doubleForKey:@"Fatality"];
    double xp_rand = drand48() - 0.5 + [self.defaults doubleForKey:@"CrashType"];

    CGFloat fontSize = [self.defaults floatForKey:@"FontSize"];
    if ([self isPreview]) {
        fontSize = PREVIEW_FONT_SIZE;
    }

    self.fatal = fatal_rand >= 0.5;
    self.xp = xp_rand >= 0.5;

    if (self.xp) {
        self.font = [NSFont fontWithName:@"LucidaConsole" size:fontSize];
    } else {
        self.font = [NSFont fontWithName:@"FixedsysTTF" size:fontSize];
    }

    if (self.xp) {
        NSInteger addr1 = rand(),
                  addr2 = rand(),
                  addr3 = rand(),
                  addr4 = rand(),
                  addr5 = rand(),
                  addr6 = rand(),
                  addr7 = rand(),
                  addr8 = rand();

        self.contentString = [NSString stringWithFormat:@"A problem has been detected and Windows has been shut down to prevent damage\nto your computer.\n\nThe problem seems to be caused by the following file: SPCMDCON.SYS\n\nPAGE_FAULT_IN_NONPAGED_AREA\n\nIf this is the first time you've seen this stop error screen,\nrestart your computer. If this screen appears again, follow\nthese steps:\n\nCheck to make sure any new hardware or software is properly installed.\nIf this is a new installation, ask your hardware or software manufacturer\nfor any Windows updates you might need.\n\nIf problems continue, disable or remove any newly installed hardware\nor software. Disable BIOS memory options such as caching or shadowing.\nIf you need to use Safe Mode to remove or disable components, restart\nyour computer, press F8 to select Advanced Startup Options, and then\nselect Safe Mode.\n\nTechnical information:\n\n*** STOP: 0x%08lX (0x%08lX, 0x%08lX, 0x%08lX, 0x%08lX)\n\n\n*** SPCMDCON.SES - Address %08lX base at %08lX, DateStamp %08lx ", addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8];
    } else if (self.fatal) {
        NSInteger addr1 = rand() % (0xFFFF - 0x1000) + 0x1000,
                  addr2 = rand(),
                  addr3 = rand(),
                  exception = rand() % (0x0F - 0x01) + 0x01;

        self.contentString = [NSString stringWithFormat:@"A fatal exception %02lX has occured at %04lX:%08lX in VxD VMM(01) + \n%08lX. The current application will be terminated.\n\n* Press any key to terminate the current application.\n* Press CTRL+ALT+RESET to restart your computer. You will\n  lose any unsaved information in all applications.\n\n\n		             Press any key to continue ", exception, addr1, addr2, addr3];
    } else {
        NSInteger addr1 = rand() % (0xFFFF - 0x1000) + 0x1000,
                  addr2 = rand(),
                  addr3 = rand(),
                  addr4 = rand() % (0xFFFF - 0x1000) + 0x1000,
                  addr5 = rand(),
                  addr6 = rand(),
                  exception = rand() % (0x0F - 0x01) + 0x01;

        self.contentString = [NSString stringWithFormat:@"An exception %02lX has occured at %04lX:%08lX in VxD VMM(01) + \n%08lX. This was called from %04lX:%08lX in VxD VMM(01) + \n%08lX. It may be possible to continue normally.\n\n* Press any key to terminate the current application.\n* Press CTRL+ALT+RESET to restart your computer. You will\n  lose any unsaved information in all applications.\n\n\n		             Press any key to continue ", exception, addr1, addr2, addr3, addr4, addr5, addr6];
    }

    self.captionString = @" Windows ";

    self.drawingAttributes = @{
        NSFontAttributeName: self.font,
        NSForegroundColorAttributeName: [NSColor whiteColor],
    };

    self.captionDrawingAttributes = @{
        NSFontAttributeName: self.font,
        NSForegroundColorAttributeName: self.backgroundColor,
        NSBackgroundColorAttributeName: self.captionBackgroundColor,
    };
}

- (void)startAnimation
{
    [super startAnimation];
    self.isAnimatingInternal = YES;
}

- (void)stopAnimation
{
    self.isAnimatingInternal = NO;
    [super stopAnimation];
}

- (void)animateOneFrame
{
    if (!self.isAnimatingInternal) {
        return;
    }

    self.hasUnderscoreSuffix = !self.hasUnderscoreSuffix;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];

    [self.backgroundColor set];
    [self.font set];

    NSString *message = [self.contentString stringByAppendingString:(self.hasUnderscoreSuffix ? @"_" : @"▋")];

    NSRectFill(rect);

    NSSize captionSize = [self.captionString sizeWithAttributes:self.captionDrawingAttributes];
    NSSize contentSize = [message sizeWithAttributes:self.drawingAttributes];

    NSRect captionRect = NSMakeRect((rect.size.width - captionSize.width) / 2.0,
                                    ((rect.size.height + contentSize.height) / 2.0) + (self.xp ? 0 : captionSize.height),
                                    captionSize.width,
                                    captionSize.height);

    NSRect contentRect = NSMakeRect((rect.size.width - contentSize.width) / 2.0,
                                    ((rect.size.height - contentSize.height) / 2.0) - (self.xp ? 0 : captionSize.height),
                                    contentSize.width,
                                    contentSize.height);

    if (!self.xp) {
        [self.captionString drawInRect:captionRect withAttributes:self.captionDrawingAttributes];
    }

    [message drawInRect:contentRect withAttributes:self.drawingAttributes];
}

+ (BOOL)performGammaFade
{
    return NO;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow *)configureSheet
{
    if (!self.configSheet) {
        NSArray *topLevelObjects;

        if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigureSheet" owner:self topLevelObjects:&topLevelObjects]) {
            NSLog(@"Failed to load configure sheet.");
            NSBeep();
        }
    }

    [self.fatalitySlider setFloatValue:[self.defaults floatForKey:@"Fatality"]];
    [self.typeSlider setFloatValue:[self.defaults floatForKey:@"CrashType"]];
    [self.fontSizeSlider setFloatValue:[self.defaults floatForKey:@"FontSize"]];

    return self.configSheet;
}

- (void)loadFontWithName:(NSString *)fontName inBundle:(NSBundle *)bundle
{
    NSArray *availableFonts = [[NSFontManager sharedFontManager] availableFonts];

    if (![availableFonts containsObject:fontName]) {
        NSURL *fontURL = [bundle URLForResource:fontName withExtension:@"ttf" subdirectory:@"Fonts"];
        if (!fontURL) {
            NSLog(@"Font %@ not found in bundle.", fontName);
            return;
        }
        CFErrorRef error = NULL;
        if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, &error)) {
            if (error) {
                CFShow(error);
                CFRelease(error);
            }
        }
    }
}

- (IBAction)configSheetCancelAction:(id)sender
{
    if ([NSWindow respondsToSelector:@selector(endSheet:)]) {
        [[self.configSheet sheetParent] endSheet:self.configSheet returnCode:NSModalResponseCancel];
    } else {
        [[NSApplication sharedApplication] endSheet:self.configSheet];
    }
}

- (IBAction)configSheetOKAction:(id)sender
{
    [self.defaults setFloat:self.fatalitySlider.floatValue forKey:@"Fatality"];
    [self.defaults setFloat:self.typeSlider.floatValue forKey:@"CrashType"];
    [self.defaults setFloat:self.fontSizeSlider.floatValue forKey:@"FontSize"];
    [self.defaults synchronize];

    [self configSheetCancelAction:sender];
}

- (IBAction)URLTextFieldClicked:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kExternalURL]];
}

- (IBAction)resetDefaultSettingsClicked:(id)sender
{
    self.fatalitySlider.floatValue = DEFAULT_FATALITY;
    self.typeSlider.floatValue = DEFAULT_CRASH_TYPE;
    self.fontSizeSlider.floatValue = DEFAULT_FONT_SIZE;
}

@end
