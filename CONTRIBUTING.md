# Contribution Guidelines
Thank you for considering a contribution to `KeepingYouAwake`! These guidelines are intended to help with avoiding rejection of code contributions and rework requests.

## Localizations
The preferred way of updating or adding a localization for `KeepingYouAwake` is by creating a pull request that **only** contains the modified `*.xliff` files within a `*.xcloc` localization catalog. Updated translations can be exported from within _Xcode_ as an `*.xcloc` catalog. Updated translations should be located in `Localizations/KeepingYouAwake/<language>.xcloc/Localized Contents/<language>.xliff`.

Localizations will usually be imported back into the app by the maintainer after the pull request is merged or after a major _Xcode_ version is released. The project configuration for a new language will also be updated by the maintainer after the pull request is merged. A pull request for a localization update should be restricted to a single language and should not include unrelated code changes.

It's not forbidden to create a pull request with modified `*.xcstrings` files, it's just not preferred and should be avoided.

### Credits (Optional)
The maintainer of this project likes to credit anyone who adds a new language or contributes major translation updates. This is done using the `Credits.rtf` file, which shows up in the "About" tab of the app settings. **If** you want to be credited, a line in the following format can be included in the pull request itself or the pull request description:

```
[language] Translation
[existing name or username] <email or URL as clickable link>
[your name or username] <email or URL as clickable link>
```

_(just follow the pattern of the other translation credits)_

## Code Style and Programming Language
There are no strict up-to-date code style rules for this project. Please follow the code style of existing code, especially when it comes to brackets (`{}`, `()`), spaces and line breaks. Please use the `Auto` helper macro for type inference of local variables, which is non-standard in Objective-C.

Objective-C, C and C++ are the preferred languages of this project and at the time of writing it is not considered to convert or accept code in any other programming language.

## Features, Structural Changes and UI Modifications
If you plan working on concrete features, structural changes to the setup of the project or any UI modifications, please start by creating a GitHub issue first as a proposal. This is the safest way to avoid pull request rejection or long feedback cycles.

## Generated Or Assisted AI Code
AI-assisted or generated code changes and pull requests are generally not accepted and will be closed. This is a project by humans for humans and its features and source code are entirely curated by actual people. The functionality of `KeepingYouAwake` can be trivially copied, so the curation aspect is integral to the project.

If you only use AI tools to help with writing the issue or pull request description, please disclose this within the description. It's generally preferred to be brief in those cases and avoid needlessly wordy generated text.

---

A pull request can always be closed. The maintainer of this project aims to provide a reason when this happens, because it's always respected that time and energy went into the creation of the pull request.


> _Thank you very much!_

> Marcel Dierkes  
> Creator and Maintainer of `KeepingYouAwake`
