# Changelog

# v2.1.0

### Added

- 🔥 **Fire Insurance Calculator** - New calculator for property insurance with zone-based risk rates
- Checkbox-based risk selection UI for Fire Insurance (Fire, Earthquake, Cyclone, Flood)
- Individual risk premium breakdown in calculation results and PDF export

### Changed

- Improved result popup to display individual risk premiums per risk type
- Enhanced history screen to properly parse and display Fire Insurance risk breakdowns
- Better responsive UI with optimized layouts

# v2.0.3 - Hotfix

This is a technical hotfix to prevent the app from crashing

## 🛠 Internal Changes

- Refactored `MainActivity.kt` to correct package namespace (`com.devcat` instead of `com.example`).
- Fixed `AndroidManifest.xml` activity registration.
- Incremented version code to **3**.

## 📦 Download

Get the update from [F-Droid / Neo Store](https://devcat-exe.github.io/devcat-fdroid-repo/repo).

# v2.0.2

## Fdroid Release!! - Check out [devcat-fdroid-repo](https://github.com/DevCat-exe/devcat-fdroid-repo)

### Fixed

- Fixed Android release signing configuration
- Fixed update issues that required uninstall/reinstall
- Ensured proper versionCode increments for seamless updates
- Proper applicationID configuration

### Improved

- Clarified update flow for external package managers (FDroid / Neo-Store)

### Permissions

- Uses **INTERNET** permission only
  - Required to check for updates and load external links
  - No background network activity

# v2.0.1

### 🐛 Bug Fixes

- **Update Checker** - Fixed crash when GitHub release has no assets
- **Sidebar** - Fixed "vv2.0.0" display to show correct version
- **Sidebar** - Now automatically closes when checking for updates
- **Snackbar** - Fixed horizontal overflow on "Checking for updates" message
- **Snackbar** - All snackbars now use consistent primary color theme
- **Snackbar** - Removed duplicate "latest version" notification

### 🎨 UI Improvements

- **About Dialog** - Increased width for better readability
- **Changelog Dialog** - Increased width for better content display
- **Result Popup** - Made fully responsive with adaptive text sizes for small screens
- **Result Popup** - Total Premium now centered and displayed vertically to prevent text truncation
- **Calculator Cards** - Fixed bottom overflow by adjusting icon size and spacing
- **Overall** - Improved spacing and sizing for phones with small screens (<380px)
- **Overall** - Reduced button padding and margins for better mobile experience

### 📱 PDF Export

- **History Screen** - Updated PDF export to match new professional format from result popup
- **Layout** - Reorganized PDF structure with better sections and formatting
- **Details** - Enhanced PDF export with improved data presentation

### 📝 Feature Updates

- **Home Screen** - Changed "Fire Insurance" card to "Health Insurance" (with heart icon)
- **Coming Soon** - Updated popup to reference Health Insurance instead of Fire Insurance
- **Risk Factor** - Corrected default risk factor from 2.45 to 2.40
- **Discount Options** - Added 30% discount option to motor insurance calculator

### ♻️ Refactoring

- **Deprecated APIs** - Removed `flutter_statusbarcolor_ns` dependency
- **Deprecated APIs** - Migrated to `SystemChrome.setSystemUIOverlayStyle()` for status bar
- **Dependencies** - Removed unused `fluttertoast` dependency

# v2.0.0

# Major Overhaul

### 🚀 Brand New Features

#### 📊 **History Tracking**

- **Complete calculation history** - Never lose your insurance calculations again!
- **Detailed view** - See all your premium breakdowns, discounts, and totals
- **Export to PDF** - Generate professional PDF reports of your calculations
- **One-tap clear** - Clean up your history with a single button press
- **Smart organization** - Automatic date sorting and categorization

#### 🎨 **UI Overhaul**

- **Calculator Cards Redesign** - Sleek new look with better proportions and spacing
- **Brand Consistent Colors** - Deep red gradients that match your brand perfectly
- **Dark Mode Perfection** - Enhanced contrast and readability in dark theme
- **Smooth Animations** - Beautiful tap feedback and transitions
- **Professional Typography** - Better font sizes and spacing throughout

#### 📱 **Motor Insurance Calculator Revamp**

- **Keyboard-Friendly** - Smart padding that adapts when keyboard appears
- **Better Layout** - Optimized for all screen sizes, especially small phones
- **Improved Inputs** - Cleaner form fields with better spacing
- **Enhanced UX** - Smoother user experience with fewer layout issues

### ✨ Major Improvements

#### 🎯 **User Experience**

- **Faster Performance** - Optimized builds and reduced layout rebuilds
- **Better Responsiveness** - Works perfectly on all device sizes
- **Enhanced Accessibility** - Improved text contrast and keyboard navigation
- **Professional Polish** - Every detail refined for a premium feel

#### 🔧 **Technical**

- **Build Optimizations** - Parallel execution, caching, and faster builds
- **Code Quality** - Fixed all deprecations and improved error handling
- **Memory Management** - Better widget lifecycle and state management
- **Stability** - Resolved all layout overflow and rendering issues

### 🐛 Bug Fixes

#### 🎨 **Visual Fixes**

- Fixed RenderFlex overflow issues on narrow screens
- Resolved keyboard interaction problems in calculator
- Corrected matrix transform deprecation warnings
- Improved text overflow handling throughout the app

#### ⚡ **Performance Fixes**

- Fixed async context usage in update checker
- Improved dropdown state management
- Enhanced error handling in all services
- Optimized widget composition for better performance

# v1.1.0

## Improvements

- Enhanced dark mode and theming across all UI, including cards and dialogs.
- Calculator cards now have white text for better readability in both light and dark modes.
- About dialog fetches and displays the changelog for the current app version, supports Markdown, and is fully scrollable.
- Update checker now shows the correct changelog and direct download button in the update popup.
- AppBar titles for calculators now use short, static display names.
- Improved error handling and user feedback throughout the app.

## Bug Fixes

- Fixed all linter and deprecation warnings.
- Fixed runtime errors related to async context usage and state management.
- Fixed text overflow and scrolling issues in dialogs and popups.

# v1.0.0

## Features

- A **Motor Insurance Calculator**.
- A **Fire Insurance Calculator** (Coming Soon).
- Added **Update Checker** to notify users of new versions

## Bug Fixes

- Fixed **Fire Calculator Card** to show a "Coming Soon" dialog.
- Removed redundant **menu button** from the app bar.
- Fixed **update checker** to show a "No Updates" notification when no updates are available.
