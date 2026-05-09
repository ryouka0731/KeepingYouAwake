//
//  KYAAppDelegate.h
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Copyright (c) 2014 Marcel Dierkes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYAAppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)showSettingsWindow:(id)sender;

/// Open the activity log JSONL file in the user's default text editor.
/// Touches the file first so the path is valid even if no session has
/// been recorded yet.
- (IBAction)showActivityLog:(id)sender;

@end

NS_ASSUME_NONNULL_END
