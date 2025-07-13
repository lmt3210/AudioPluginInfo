//
// AppDelegate.m
// 
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//    distribution.
//

#import <sys/types.h>
#import <pwd.h>
#import <uuid/uuid.h>
#import <sys/utsname.h>

#import "AppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create the master View Controller
    self.masterViewController = [[MasterViewController alloc] 
        initWithNibName:@"MasterViewController" bundle:nil];
    
    // Update color
    [self.window setBackgroundColor:[NSColor colorWithRed:0.2
                                     green:0.2 blue:0.2 alpha:1.0]];

    // Add the view controller to the window's content view
    [self.window.contentView addSubview:self.masterViewController.view];
    self.masterViewController.view.frame =
        ((NSView*)self.window.contentView).bounds;

    // Set up logging
    mLog = os_log_create("com.larrymtaylor.AudioPluginInfo", "AppDelegate");
    NSString *path =
        [[NSFileManager defaultManager] applicationSupportDirectory];
    mLogFile = [[NSString alloc] initWithFormat:@"%@/logFile.txt", path];
    UInt64 fileSize = [[[NSFileManager defaultManager]
                        attributesOfItemAtPath:mLogFile error:nil] fileSize];

    if (fileSize > (1024 * 1024))
    {
        [[NSFileManager defaultManager] removeItemAtPath:mLogFile error:nil];
    }

    // Get macOS version
    NSOperatingSystemVersion sysVersion =
        [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *systemVersion = [NSString stringWithFormat:@"%ld.%ld",
                               sysVersion.majorVersion,
                               sysVersion.minorVersion];
    
    // Log some basic information
    NSBundle *appBundle = [NSBundle mainBundle];
    NSDictionary *appInfo = [appBundle infoDictionary];
    NSString *appVersion =
        [appInfo objectForKey:@"CFBundleShortVersionString"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy h:mm a"];
    NSString *day = [dateFormatter stringFromDate:[NSDate date]];
    struct utsname osinfo;
    uname(&osinfo);
    NSString *info = [NSString stringWithUTF8String:osinfo.version];
    LTLog(mLog, mLogFile, OS_LOG_TYPE_INFO,
          @"AudioPluginInfo v%@ running on macOS %@ (%@)\n%@",
          appVersion, systemVersion, day, info);

    // Version check
    mVersionCheck = [[LTVersionCheck alloc] initWithAppName:@"AudioPluginInfo"
                     withAppVersion:appVersion
                     withLogHandle:mLog withLogFile:mLogFile];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return TRUE;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)cleanup
{
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self cleanup];
}

@end
