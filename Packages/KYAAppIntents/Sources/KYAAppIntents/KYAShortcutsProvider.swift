import AppIntents

/// Surfaces the three intents to Shortcuts.app and Spotlight as ready-made
/// quick actions. Phrases below are intentionally short — Shortcuts uses
/// them as Siri trigger phrases.
@available(macOS 13.0, *)
public struct KYAShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: KYAActivateIntent(),
            phrases: [
                "Activate \(.applicationName)",
                "Keep my Mac awake with \(.applicationName)",
            ],
            shortTitle: "Activate",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: KYADeactivateIntent(),
            phrases: [
                "Deactivate \(.applicationName)",
                "Let my Mac sleep with \(.applicationName)",
            ],
            shortTitle: "Deactivate",
            systemImageName: "cup.and.saucer"
        )
        AppShortcut(
            intent: KYAToggleIntent(),
            phrases: [
                "Toggle \(.applicationName)",
            ],
            shortTitle: "Toggle",
            systemImageName: "power"
        )
    }
}
