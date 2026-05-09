//
//  KYAScripting.h
//  KeepingYouAwake
//
//  AppleScript / sdef glue (#46). Three NSScriptCommand subclasses
//  for activate / deactivate / toggle, plus a KYAScriptingProxy
//  vended as the singleton `kya` object so callers can read
//  `active`, `remaining seconds`, and `source`.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYAActivateScriptCommand : NSScriptCommand
@end

@interface KYADeactivateScriptCommand : NSScriptCommand
@end

@interface KYAToggleScriptCommand : NSScriptCommand
@end

/// Read-only proxy exposed as the singleton `kya` object. Reads its
/// state from the activity log (same path as the CLI / MCP server).
@interface KYAScriptingProxy : NSObject
+ (instancetype)sharedProxy;
@property (readonly, nonatomic, getter=isActive) BOOL active;
@property (readonly, nonatomic) NSInteger remainingSeconds;   // -1 if indefinite or inactive
@property (readonly, copy, nonatomic) NSString *source;       // "" if inactive
@end

NS_ASSUME_NONNULL_END
