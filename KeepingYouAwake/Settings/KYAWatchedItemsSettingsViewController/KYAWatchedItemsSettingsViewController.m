//
//  KYAWatchedItemsSettingsViewController.m
//  KeepingYouAwake
//
//  Created for issue #40 — Watched Items settings pane.
//

#import "KYAWatchedItemsSettingsViewController.h"
#import <KYACommon/KYACommon.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>
#import "KYALocalizedStrings.h"

#if __has_include(<UniformTypeIdentifiers/UniformTypeIdentifiers.h>)
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#endif

typedef NS_ENUM(NSInteger, KYAWatchedItemsListKind) {
    KYAWatchedItemsListKindWiFiSSIDs = 0,
    KYAWatchedItemsListKindApplications,
    KYAWatchedItemsListKindDownloadDirectories,
};

@interface KYAWatchedItemsSettingsViewController ()
@property (nonatomic) NSTableView *ssidTableView;
@property (nonatomic) NSTableView *applicationsTableView;
@property (nonatomic) NSTableView *directoriesTableView;

@property (nonatomic) NSSegmentedControl *ssidControl;
@property (nonatomic) NSSegmentedControl *applicationsControl;
@property (nonatomic) NSSegmentedControl *directoriesControl;

@property (nonatomic) NSMutableArray<NSString *> *ssids;
@property (nonatomic) NSMutableArray<NSString *> *bundleIdentifiers;
@property (nonatomic) NSMutableArray<NSString *> *directories;
@end

@implementation KYAWatchedItemsSettingsViewController

+ (NSImage *)tabViewItemImage
{
    if(@available(macOS 11.0, *))
    {
        return [NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil];
    }
    else
    {
        return [NSImage imageNamed:NSImageNameListViewTemplate];
    }
}

+ (NSString *)preferredTitle
{
    return KYA_SETTINGS_L10N_WATCHED_ITEMS;
}

- (BOOL)resizesView
{
    return NO;
}

#pragma mark - Life Cycle

- (instancetype)init
{
    // Bypass KYASettingsContentViewController's Nib-loading -init by
    // going straight to NSViewController's designated initializer with a
    // nil Nib name. We build the view hierarchy in -loadView.
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        self.title = [[self class] preferredTitle];
    }
    return self;
}

- (void)loadView
{
    [self loadModel];

    Auto rootView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 480.0, 460.0)];

    Auto stackView = [NSStackView new];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.alignment = NSLayoutAttributeLeading;
    stackView.distribution = NSStackViewDistributionFill;
    stackView.spacing = 16.0;
    stackView.edgeInsets = NSEdgeInsetsMake(16.0, 20.0, 16.0, 20.0);
    [rootView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:rootView.topAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
    ]];

    NSTableView *ssidTableView = nil;
    NSSegmentedControl *ssidControl = nil;
    [stackView addArrangedSubview:[self sectionViewWithTitle:KYA_L10N_WATCHED_WIFI_SSIDS
                                                        hint:KYA_L10N_WATCHED_WIFI_SSIDS_HINT
                                                    editable:YES
                                                   tableView:&ssidTableView
                                                     control:&ssidControl
                                                        kind:KYAWatchedItemsListKindWiFiSSIDs]];
    self.ssidTableView = ssidTableView;
    self.ssidControl = ssidControl;

    NSTableView *applicationsTableView = nil;
    NSSegmentedControl *applicationsControl = nil;
    [stackView addArrangedSubview:[self sectionViewWithTitle:KYA_L10N_WATCHED_APPLICATIONS
                                                        hint:KYA_L10N_WATCHED_APPLICATIONS_HINT
                                                    editable:NO
                                                   tableView:&applicationsTableView
                                                     control:&applicationsControl
                                                        kind:KYAWatchedItemsListKindApplications]];
    self.applicationsTableView = applicationsTableView;
    self.applicationsControl = applicationsControl;

    NSTableView *directoriesTableView = nil;
    NSSegmentedControl *directoriesControl = nil;
    [stackView addArrangedSubview:[self sectionViewWithTitle:KYA_L10N_WATCHED_DOWNLOAD_DIRECTORIES
                                                        hint:KYA_L10N_WATCHED_DOWNLOAD_DIRECTORIES_HINT
                                                    editable:NO
                                                   tableView:&directoriesTableView
                                                     control:&directoriesControl
                                                        kind:KYAWatchedItemsListKindDownloadDirectories]];
    self.directoriesTableView = directoriesTableView;
    self.directoriesControl = directoriesControl;

    self.view = rootView;

    [self updateRemoveButtonsEnabledState];
}

#pragma mark - Section Builder

- (NSView *)sectionViewWithTitle:(NSString *)title
                            hint:(NSString *)hint
                        editable:(BOOL)editable
                       tableView:(NSTableView * _Nullable __autoreleasing * _Nonnull)outTableView
                         control:(NSSegmentedControl * _Nullable __autoreleasing * _Nonnull)outControl
                            kind:(KYAWatchedItemsListKind)kind
{
    Auto section = [NSStackView new];
    section.translatesAutoresizingMaskIntoConstraints = NO;
    section.orientation = NSUserInterfaceLayoutOrientationVertical;
    section.alignment = NSLayoutAttributeLeading;
    section.spacing = 6.0;

    Auto titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    [section addArrangedSubview:titleLabel];

    Auto hintLabel = [NSTextField wrappingLabelWithString:hint];
    hintLabel.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    hintLabel.textColor = NSColor.secondaryLabelColor;
    [section addArrangedSubview:hintLabel];

    // Table view inside a scroll view.
    Auto tableView = [NSTableView new];
    tableView.headerView = nil;
    tableView.usesAlternatingRowBackgroundColors = YES;
    tableView.allowsMultipleSelection = NO;
    tableView.rowSizeStyle = NSTableViewRowSizeStyleDefault;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tag = kind;

    Auto column = [[NSTableColumn alloc] initWithIdentifier:@"value"];
    column.editable = editable;
    column.resizingMask = NSTableColumnAutoresizingMask;
    [tableView addTableColumn:column];
    tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;

    Auto scrollView = [NSScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.documentView = tableView;
    [section addArrangedSubview:scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.heightAnchor constraintEqualToConstant:96.0],
        [scrollView.widthAnchor constraintEqualToConstant:440.0],
    ]];

    // Add / Remove segmented control.
    Auto control = [NSSegmentedControl new];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.segmentStyle = NSSegmentStyleSmallSquare;
    control.trackingMode = NSSegmentSwitchTrackingMomentary;
    control.segmentCount = 2;
    if(@available(macOS 11.0, *))
    {
        [control setImage:[NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:NSLocalizedString(@"Add", @"Add")] forSegment:0];
        [control setImage:[NSImage imageWithSystemSymbolName:@"minus" accessibilityDescription:NSLocalizedString(@"Remove", @"Remove")] forSegment:1];
    }
    else
    {
        [control setImage:[NSImage imageNamed:NSImageNameAddTemplate] forSegment:0];
        [control setImage:[NSImage imageNamed:NSImageNameRemoveTemplate] forSegment:1];
    }
    [control setWidth:28.0 forSegment:0];
    [control setWidth:28.0 forSegment:1];
    control.target = self;
    control.action = @selector(segmentedControlAction:);
    control.tag = kind;
    [section addArrangedSubview:control];

    *outTableView = tableView;
    *outControl = control;
    return section;
}

#pragma mark - Model

- (void)loadModel
{
    Auto defaults = NSUserDefaults.standardUserDefaults;
    self.ssids = [[defaults kya_watchedWiFiSSIDs] mutableCopy] ?: [NSMutableArray new];
    self.bundleIdentifiers = [[defaults kya_watchedApplicationBundleIdentifiers] mutableCopy] ?: [NSMutableArray new];
    self.directories = [[defaults kya_downloadDirectories] mutableCopy] ?: [NSMutableArray new];
}

- (NSMutableArray<NSString *> *)modelForKind:(KYAWatchedItemsListKind)kind
{
    switch(kind)
    {
        case KYAWatchedItemsListKindWiFiSSIDs: return self.ssids;
        case KYAWatchedItemsListKindApplications: return self.bundleIdentifiers;
        case KYAWatchedItemsListKindDownloadDirectories: return self.directories;
    }
    return [NSMutableArray new];
}

- (NSTableView *)tableViewForKind:(KYAWatchedItemsListKind)kind
{
    switch(kind)
    {
        case KYAWatchedItemsListKindWiFiSSIDs: return self.ssidTableView;
        case KYAWatchedItemsListKindApplications: return self.applicationsTableView;
        case KYAWatchedItemsListKindDownloadDirectories: return self.directoriesTableView;
    }
    return nil;
}

- (void)persistModelForKind:(KYAWatchedItemsListKind)kind
{
    Auto defaults = NSUserDefaults.standardUserDefaults;
    switch(kind)
    {
        case KYAWatchedItemsListKindWiFiSSIDs:
            defaults.kya_watchedWiFiSSIDs = (self.ssids.count > 0) ? [self.ssids copy] : nil;
            break;
        case KYAWatchedItemsListKindApplications:
            defaults.kya_watchedApplicationBundleIdentifiers = (self.bundleIdentifiers.count > 0) ? [self.bundleIdentifiers copy] : nil;
            break;
        case KYAWatchedItemsListKindDownloadDirectories:
            defaults.kya_downloadDirectories = (self.directories.count > 0) ? [self.directories copy] : nil;
            break;
    }
}

/// Inserts `string` (trimmed) into the given list unless it is empty or a
/// case-insensitive duplicate. Returns YES if inserted.
- (BOOL)addString:(NSString *)string toKind:(KYAWatchedItemsListKind)kind
{
    Auto trimmed = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(trimmed.length == 0) { return NO; }

    Auto model = [self modelForKind:kind];
    for(NSString *existing in model)
    {
        if([existing caseInsensitiveCompare:trimmed] == NSOrderedSame) { return NO; }
    }
    [model addObject:trimmed];
    [self persistModelForKind:kind];
    [[self tableViewForKind:kind] reloadData];
    [self updateRemoveButtonsEnabledState];
    return YES;
}

#pragma mark - Actions

- (void)segmentedControlAction:(NSSegmentedControl *)sender
{
    Auto kind = (KYAWatchedItemsListKind)sender.tag;
    if(sender.selectedSegment == 0)
    {
        [self addItemForKind:kind];
    }
    else
    {
        [self removeSelectedItemForKind:kind];
    }
}

- (void)addItemForKind:(KYAWatchedItemsListKind)kind
{
    switch(kind)
    {
        case KYAWatchedItemsListKindWiFiSSIDs:
            [self addEmptySSIDRowAndBeginEditing];
            break;
        case KYAWatchedItemsListKindApplications:
            [self presentApplicationOpenPanel];
            break;
        case KYAWatchedItemsListKindDownloadDirectories:
            [self presentDirectoryOpenPanel];
            break;
    }
}

- (void)addEmptySSIDRowAndBeginEditing
{
    // Append a placeholder row and immediately begin editing it. The value
    // is committed (trimmed / deduped / dropped-if-empty) when the cell-based
    // table calls -tableView:setObjectValue:forTableColumn:row: on edit end.
    [self.ssids addObject:@""];
    [self.ssidTableView reloadData];
    Auto row = (NSInteger)(self.ssids.count - 1);
    [self.ssidTableView scrollRowToVisible:row];
    [self.ssidTableView editColumn:0 row:row withEvent:nil select:YES];
    [self updateRemoveButtonsEnabledState];
}

- (void)removeSelectedItemForKind:(KYAWatchedItemsListKind)kind
{
    Auto tableView = [self tableViewForKind:kind];
    Auto selectedRow = tableView.selectedRow;
    Auto model = [self modelForKind:kind];
    if(selectedRow < 0 || selectedRow >= (NSInteger)model.count) { return; }

    [model removeObjectAtIndex:(NSUInteger)selectedRow];
    [self persistModelForKind:kind];
    [tableView reloadData];
    [self updateRemoveButtonsEnabledState];
}

#pragma mark - Open Panels

- (void)presentApplicationOpenPanel
{
    Auto panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.canCreateDirectories = NO;
    panel.prompt = KYA_L10N_WATCHED_ITEMS_CHOOSE_APPLICATION;
    panel.title = KYA_L10N_WATCHED_ITEMS_CHOOSE_APPLICATION;
    panel.treatsFilePackagesAsDirectories = NO;

#if __has_include(<UniformTypeIdentifiers/UniformTypeIdentifiers.h>)
    if(@available(macOS 11.0, *))
    {
        panel.allowedContentTypes = @[ UTTypeApplicationBundle ];
    }
    else
#endif
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        panel.allowedFileTypes = @[ @"app" ];
#pragma clang diagnostic pop
    }

    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) { return; }
        if(result != NSModalResponseOK) { return; }
        NSURL *url = panel.URL;
        if(url == nil) { return; }

        NSBundle *bundle = [NSBundle bundleWithURL:url];
        NSString *bundleIdentifier = bundle.bundleIdentifier;
        if(bundleIdentifier.length == 0)
        {
            NSBeep();
            Auto alert = [NSAlert new];
            alert.messageText = KYA_L10N_WATCHED_ITEMS_NO_BUNDLE_IDENTIFIER_TITLE;
            alert.informativeText = KYA_L10N_WATCHED_ITEMS_NO_BUNDLE_IDENTIFIER_MESSAGE;
            [alert addButtonWithTitle:KYA_L10N_OK];
            [alert beginSheetModalForWindow:strongSelf.view.window completionHandler:nil];
            return;
        }
        [strongSelf addString:bundleIdentifier toKind:KYAWatchedItemsListKindApplications];
    }];
}

- (void)presentDirectoryOpenPanel
{
    Auto panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.canCreateDirectories = YES;
    panel.prompt = KYA_L10N_WATCHED_ITEMS_CHOOSE_FOLDER;
    panel.title = KYA_L10N_WATCHED_ITEMS_CHOOSE_FOLDER;

    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if(strongSelf == nil) { return; }
        if(result != NSModalResponseOK) { return; }
        NSURL *url = panel.URL;
        if(url == nil) { return; }
        NSString *path = [url.path stringByAbbreviatingWithTildeInPath];
        [strongSelf addString:path toKind:KYAWatchedItemsListKindDownloadDirectories];
    }];
}

#pragma mark - Remove Button State

- (void)updateRemoveButtonsEnabledState
{
    NSSegmentedControl *controls[] = { self.ssidControl, self.applicationsControl, self.directoriesControl };
    for(size_t i = 0; i < sizeof(controls) / sizeof(controls[0]); i++)
    {
        NSSegmentedControl *control = controls[i];
        if(control == nil) { continue; }
        Auto kind = (KYAWatchedItemsListKind)control.tag;
        BOOL hasSelection = ([self tableViewForKind:kind].selectedRow >= 0);
        [control setEnabled:hasSelection forSegment:1];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (NSInteger)[self modelForKind:(KYAWatchedItemsListKind)tableView.tag].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Auto model = [self modelForKind:(KYAWatchedItemsListKind)tableView.tag];
    if(row < 0 || row >= (NSInteger)model.count) { return @""; }
    return model[(NSUInteger)row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // Only the SSID column is editable.
    Auto kind = (KYAWatchedItemsListKind)tableView.tag;
    if(kind != KYAWatchedItemsListKindWiFiSSIDs) { return; }

    Auto newValue = [object isKindOfClass:[NSString class]] ? (NSString *)object : @"";
    Auto trimmed = [newValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    if(row < 0 || row >= (NSInteger)self.ssids.count) { return; }

    Auto previousValue = self.ssids[(NSUInteger)row];
    BOOL wasPlaceholder = (previousValue.length == 0);

    BOOL isDuplicate = NO;
    for(NSInteger i = 0; i < (NSInteger)self.ssids.count; i++)
    {
        if(i == row) { continue; }
        if([self.ssids[(NSUInteger)i] caseInsensitiveCompare:trimmed] == NSOrderedSame) { isDuplicate = YES; break; }
    }

    if(trimmed.length == 0 || (isDuplicate && wasPlaceholder))
    {
        // Empty input, or a freshly-added placeholder row resolved to a
        // duplicate — discard the row.
        [self.ssids removeObjectAtIndex:(NSUInteger)row];
    }
    else if(isDuplicate)
    {
        // Editing an existing entry into a duplicate of another — keep the
        // previous value, do not destroy the row.
        [tableView reloadData];
        [self updateRemoveButtonsEnabledState];
        return;
    }
    else
    {
        self.ssids[(NSUInteger)row] = trimmed;
    }

    [self persistModelForKind:KYAWatchedItemsListKindWiFiSSIDs];
    [tableView reloadData];
    [self updateRemoveButtonsEnabledState];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self updateRemoveButtonsEnabledState];
}

@end
