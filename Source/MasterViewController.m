//
// MasterViewController.m
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

#import "MasterViewController.h"
#import "PluginData.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation MasterViewController

@synthesize mPlugins;
@synthesize mPluginTableView;
@synthesize mInfoField;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    // Set up logging
    mLog = os_log_create("com.larrymtaylor.AudioPluginInfo", "MasterView");
    NSString *path =
        [[NSFileManager defaultManager] applicationSupportDirectory];
    mLogFile = [[NSString alloc] initWithFormat:@"%@/logFile.txt", path];
    
    return self;
}

- (NSView *)tableView:(NSTableView *)tableView 
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    // Get a new ViewCell
    NSTableCellView *cellView = 
        [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    LTPluginData *pluginData = [mPlugins objectAtIndex:row];
    NSString *text = @"";
    
    if ([tableColumn.identifier isEqualToString:@"name"] == YES)
    {
        (pluginData.name == nil) ? (text = @"N/A") : (text = pluginData.name);
    }
    else if ([tableColumn.identifier isEqualToString:@"version"] == YES)
    {
        (pluginData.version == nil) ? (text = @"N/A") :
            (text = pluginData.version);
    }
    else if ([tableColumn.identifier isEqualToString:@"minOS"] == YES)
    {
        text = @"N/A";
        
        if ([pluginData.name containsString:@"View"] == NO)
        {
            if ((pluginData.minOS != nil) &&
                ([pluginData.minOS isKindOfClass:[NSString class]]) &&
                ([pluginData.minOS containsString:@","] == NO))
            {
                text = pluginData.minOS;
            }
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"type"] == YES)
    {
        (pluginData.type == nil) ? (text = @"N/A") : (text = pluginData.type);
    }
    else if ([tableColumn.identifier isEqualToString:@"arch"] == YES)
    {
        if (pluginData.arch != nil)
        {
            if ([pluginData.arch containsString:@"Arch:"] == YES)
            {
                NSArray *archs =
                    [pluginData.arch componentsSeparatedByCharactersInSet:
                    [NSCharacterSet characterSetWithCharactersInString:@":,"]];
                NSMutableString *archString =
                    [NSMutableString stringWithString:@""];
            
                for (int i = 0; i < [archs count]; i++)
                {
                    if (([archs[i] isEqualToString:@"I64"]) ||
                        ([archs[i] isEqualToString:@"A64"]) ||
                        ([archs[i] isEqualToString:@"I32"]) ||
                        ([archs[i] isEqualToString:@"PPC"]) ||
                        ([archs[i] isEqualToString:@"N/A"]))
                    {
                        [archString appendFormat:@"%@  ", archs[i]];
                    }
                }

                text = archString;
            }
            else
            {
                text = @"N/A";
            }
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"path"] == YES)
    {
        (pluginData.path == nil) ? (text = @"N/A") : (text = pluginData.path);
    }

    cellView.textField.stringValue = text;

    return cellView;
}

- (void)loadView
{
    [super loadView];
    
    // Initialize variables
    mPlugins = [[NSMutableArray alloc] init];
    mText = [[NSString alloc] init];

    // Set column sort descriptors
    NSArray<NSTableColumn*> *columns = [mPluginTableView tableColumns];
    
    for (int i = 0; i < [columns count]; i++)
    {
        NSTableColumn *column = [columns objectAtIndex:i];
        NSSortDescriptor *sortDescriptor =
            [NSSortDescriptor sortDescriptorWithKey:[column identifier]
             ascending:YES selector:@selector(compare:)];
        [column setSortDescriptorPrototype:sortDescriptor];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger rows = [mPluginTableView numberOfSelectedRows];
    
    if (rows > 1)
    {
        [mInfoField setStringValue:
         [NSString stringWithFormat:@"%li plugins selected.", rows]];
    }
    else if (rows > 0)
    {
        [mInfoField setStringValue:
         [NSString stringWithFormat:@"%li plugin selected.", rows]];
    }
    else
    {
        [mInfoField setStringValue:@""];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [mPlugins count];
}

- (void)tableView:(NSTableView *)aTableView
        sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray<NSTableColumn*> *columns = [mPluginTableView tableColumns];
    NSTableColumn *column =
        [columns objectAtIndex:[aTableView selectedColumn]];
    NSSortDescriptor *sd = [column sortDescriptorPrototype];
    NSSortDescriptor *sdr = [sd reversedSortDescriptor];
    [column setSortDescriptorPrototype:sdr];
    NSArray *sortedPlugins = [mPlugins sortedArrayUsingDescriptors:@[sd]];
    mPlugins = (NSMutableArray *)sortedPlugins;
    [mPluginTableView reloadData];
}

- (void)pluginListReadyTimer:(NSTimer *)timer
{
    if (mReady == false)
    {
        NSString *text = [NSString stringWithFormat:@"%@.", mText];
        [mInfoField setStringValue:text];
        mText = [text copy];
        return;
    }
    
    [mReadyTimer invalidate];
    mReadyTimer = nil;
    
    NSSortDescriptor *sortDescriptor =
        [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES
         selector:@selector(compare:)];
    [mPlugins sortUsingDescriptors:@[sortDescriptor]];
    
    NSString *text = [NSString stringWithFormat:
                      @"%@done.  Found %lu plugins.", mText,
                      (unsigned long)[mPlugins count]];
    [mInfoField setStringValue:text];
    [mPluginTableView reloadData];
}

- (void)getPluginList
{
    mText = @"Gathering list of plugins...";
    [mInfoField setStringValue:mText];
    
    // Process VST plugins in system folder
    NSURL *dirUrl =
        [[NSURL alloc] initWithString:@"/Library/Audio/Plug-Ins/VST"];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"vst"]))
        {
            LTPluginData *plugin =
                [[LTPluginData alloc] initWithType:@"VST" withPath:[url path]];
            [mPlugins addObject:plugin];
        }
    }
    
    // Process VST plugins in user folder
    struct passwd *pw = getpwuid(getuid());
    NSString *realHomeDir = [NSString stringWithUTF8String:pw->pw_dir];
    NSString *homeCompDir =
        [NSString stringWithFormat:@"%@/Library/Audio/Plug-Ins/VST",
         realHomeDir];
    dirUrl = [[NSURL alloc] initWithString:homeCompDir];
    enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"vst"]))
        {
            LTPluginData *plugin =
                [[LTPluginData alloc] initWithType:@"VST" withPath:[url path]];
            [mPlugins addObject:plugin];
        }
    }
            
    // Process VST3 plugins in system folder
    dirUrl = [[NSURL alloc] initWithString:@"/Library/Audio/Plug-Ins/VST3"];
    enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"vst3"]))
        {
            LTPluginData *plugin =
                [[LTPluginData alloc] initWithType:@"VST3" withPath:[url path]];
            [mPlugins addObject:plugin];
        }
    }
    
    // Process VST3 plugins in user folder
    homeCompDir =
        [NSString stringWithFormat:@"%@/Library/Audio/Plug-Ins/VST3",
         realHomeDir];
    dirUrl = [[NSURL alloc] initWithString:homeCompDir];
    enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"vst3"]))
        {
            LTPluginData *plugin =
                [[LTPluginData alloc] initWithType:@"VST3" withPath:[url path]];
            [mPlugins addObject:plugin];
        }
    }
    
    // Process AAX plugins in system folder
    dirUrl = 
        [[NSURL alloc]
         initWithString:@"/Library/Application Support/Avid/Audio/Plug-Ins"];
    enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:[dirUrl URLByResolvingSymlinksInPath]
        includingPropertiesForKeys:nil
        options:NSDirectoryEnumerationSkipsPackageDescendants
        errorHandler:nil];
    
    for (NSURL *url in enumerator)
    {
        if ((url != nil) && ([[[url lastPathComponent] pathExtension]
             isEqualToString:@"aaxplugin"]))
        {
            LTPluginData *plugin =
                [[LTPluginData alloc] initWithType:@"AAX" withPath:[url path]];
            [mPlugins addObject:plugin];
        }
    }
     
    [self getArch];
    self->mReady = true;
}

- (IBAction)scan:(id)sender
{
    // Clear list
    mPlugins = [[NSMutableArray alloc] init];
    [mPluginTableView reloadData];
    
    // Start timer to wait for list ready
    mReady = false;
    mReadyTimer = [NSTimer scheduledTimerWithTimeInterval:1
                   target:self selector:@selector(pluginListReadyTimer:)
                   userInfo:nil repeats:YES];
    
    // Start task to get list
    [self getPluginList];
}

- (void)getArch
{
    for (int j = 0; j < [mPlugins count]; j++)
    {
        LTPluginData *pluginData = mPlugins[j];
        NSString *execDir =
            [[NSString alloc] initWithFormat:@"%@/Contents/MacOS",
            pluginData.path];
        NSString* execDirEscaped =
            [execDir stringByAddingPercentEncodingWithAllowedCharacters:
             [NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *execUrl = [[NSURL alloc] initWithString:execDirEscaped];
        NSDirectoryEnumerator *execEnum =
            [[NSFileManager defaultManager]
             enumeratorAtURL:[execUrl URLByResolvingSymlinksInPath]
             includingPropertiesForKeys:nil
             options:NSDirectoryEnumerationSkipsPackageDescendants
             errorHandler:nil];
            
        NSTask *task = [[NSTask alloc] init];
        NSArray *args =
            [NSArray arrayWithObjects:[[execEnum nextObject] path], nil];
        
        if ([args count] != 0)
        {
            task.launchPath = @"/usr/bin/file";
            task.arguments = args;
            NSPipe *pipe = [NSPipe pipe];
            task.standardOutput = pipe;
            
            pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *h)
            {
                self->mArchResult = [h readDataToEndOfFile];
                [h closeFile];
            };
            
            [task launch];
            [task waitUntilExit];
            
            char string[100] = { 0 };
            unsigned char *result = (unsigned char *)[mArchResult bytes];
            
            if (result != nil)
            {
                NSUInteger data_length = [mArchResult length];
                result[data_length - 1] = 0;
                strcat(string, "Arch:");
                
                if (strstr((const char *)result, "arm64"))
                {
                    strcat(string, "A64,");
                }
                
                if (strstr((const char *)result, "x86_64"))
                {
                    strcat(string, "I64,");
                }
                
                if (strstr((const char *)result, "i386"))
                {
                    strcat(string, "I32,");
                }
                
                if (strstr((const char *)result, "ppc"))
                {
                    strcat(string, "PPC,");
                }
            }
            
            pluginData.arch = [NSString stringWithCString:string
                               encoding:NSUTF8StringEncoding];
        }
    }
}

@end
