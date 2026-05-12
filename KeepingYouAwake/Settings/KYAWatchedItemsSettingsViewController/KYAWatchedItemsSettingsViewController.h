//
//  KYAWatchedItemsSettingsViewController.h
//  KeepingYouAwake
//
//  Created for issue #40 — Watched Items settings pane.
//

#import <Cocoa/Cocoa.h>
#import "KYASettingsContentViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// Shows "Watched Items" settings: add/remove list editors for the
/// watched Wi-Fi SSIDs, watched application bundle identifiers and
/// download directories user defaults arrays.
///
/// @discussion This view controller builds its view hierarchy
/// programmatically in `-loadView` and therefore does not require a Nib.
@interface KYAWatchedItemsSettingsViewController : KYASettingsContentViewController <NSTableViewDataSource, NSTableViewDelegate>
@end

NS_ASSUME_NONNULL_END
