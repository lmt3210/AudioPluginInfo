//
// PluginData.m
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

#import "PluginData.h"

@implementation LTPluginData

- (id)initWithType:(NSString *)type withPath:(NSString *)path
{
    if ((self = [super init]))
    {
        // Set up logging
        mLog = os_log_create("com.larrymtaylor.AppInfo", "LTPluginData");

        self.name = @"";
        self.version = @"";
        self.minOS = @"";
        self.type = type;
        self.arch = @"";
        self.path = path;

        NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
        NSDictionary *pluginInfo = [bundle infoDictionary];
        NSString *displayName =
            [pluginInfo objectForKey:@"CFBundleDisplayName"];
        NSString *bundleName = [pluginInfo objectForKey:@"CFBundleName"];
        NSString *bundleID = [pluginInfo objectForKey:@"CFBundleIdentifier"];

        if ((displayName != nil) && ([displayName isEqualToString:@""] == NO))
        {
             self.name = displayName;
        }
        else if ((bundleName != nil) &&
                 ([bundleName isEqualToString:@""] == NO))
        {
             self.name = bundleName;
        }
        else if ((bundleID != nil) && ([bundleID isEqualToString:@""] == NO))
        {
            self.name = bundleID;
        }
        else
        {
             self.name = @"N/A";
        }

        NSString *shortVersion =
            [pluginInfo objectForKey:@"CFBundleShortVersionString"];
        NSString *bundleVersion = [pluginInfo objectForKey:@"CFBundleVersion"];

        if ((shortVersion != nil) &&
            ([shortVersion isEqualToString:@""] == NO))
        {
             self.version = shortVersion;
        }
        else if ((bundleVersion != nil)  &&
                 ([bundleVersion isEqualToString:@""] == NO))
        {
             self.version = bundleVersion;
        }
        else
        {
             self.version = @"N/A";
        }

        NSString *minOS = [pluginInfo objectForKey:@"LSMinimumSystemVersion"];
        (minOS == nil) ? (self.minOS = @"N/A") : (self.minOS = minOS);
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    LTPluginData *plugin = [[[self class] allocWithZone:zone] init];
    
    plugin.name = [self.name copyWithZone:zone];
    plugin.version = [self.version copyWithZone:zone];
    plugin.minOS = [self.minOS copyWithZone:zone];
    plugin.type = [self.type copyWithZone:zone];
    plugin.arch = [self.arch copyWithZone:zone];
    plugin.path = [self.path copyWithZone:zone];
    
    return plugin;
}

@end
