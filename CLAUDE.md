# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

meSync is an iOS personal productivity and habit-tracking application built with SwiftUI and SwiftData. The app helps users synchronize their daily routines by managing tasks, habits, and medications in one unified interface.

## Build and Development Commands

### Building the Project
```bash
# Open the project in Xcode
open meSync.xcodeproj

# Build from command line (requires Xcode Command Line Tools)
xcodebuild -project meSync.xcodeproj -scheme meSync -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project meSync.xcodeproj -scheme meSync -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'

# Run SwiftLint (if configured)
swiftlint autocorrect

# Generate documentation
jazzy --clean --build-tool-arguments -scheme,meSync

# Profile performance
instruments -t "Time Profiler" -D trace.trace meSync.app
```

### Common Development Tasks
- **Build**: Cmd+B in Xcode
- **Run**: Cmd+R in Xcode  
- **Test**: Cmd+U in Xcode
- **Clean**: Cmd+Shift+K in Xcode
- **Run single test**: Click the diamond next to test method in Xcode

### Git Commands
```bash
# Commit with co-author (as per build-log.md convention)
git commit -m "Your message

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Architecture Overview

### Design System Philosophy
The app implements a CSS-like centralized design system inspired by web development:

1. **AppTheme.swift** - Design tokens hub containing:
   - `AppColors` - All color definitions (primary, secondary, backgrounds, states)
   - `AppSpacing` - Standardized spacing scale (xs through xxxl)
   - `AppTypography` - Font styles and sizes
   - `AppIcons` - SF Symbol icon references
   - `AppDimensions` - Fixed dimensions for UI elements

2. **ViewExtensions.swift** - Reusable view modifiers that work like CSS classes:
   - `.primaryTitleStyle()`, `.subtitleStyle()`, `.captionStyle()` - Text styles
   - `.sectionCardStyle()`, `.headerContainerStyle()` - Container styles
   - `.standardPadding()`, `.standardHorizontalPadding()` - Spacing helpers

3. **ButtonStyles.swift** - Button-specific styles and effects

**Important**: Never use hardcoded values. Always reference the design system.

### State Management Architecture

1. **QuickAddState** - Centralized navigation state using enum pattern:
   - States: `hidden`, `accordion`, `taskForm`, `habitForm`, `medicationForm`
   - Manages form transitions and data flow
   - Single source of truth for navigation

2. **SwiftData Models** - Persistence layer:
   - `TaskData` - Simple task model
   - `HabitData` - Complex habit model with repetition logic
   - `MedicationData` - Medication tracking with dose times
   - `HabitInstanceData` - Persists habit completion states
   - `MedicationInstanceData` - Persists medication taken states

3. **Dynamic Instance Generation**:
   - Habits and medications don't create database entries for each occurrence
   - `HabitInstance` and `MedicationInstance` are generated on-demand
   - 3-day window optimization for performance
   - State tracked via unique keys: `"{id}_{date}_{dose}"`

### Tab Navigation Architecture

The app uses a 5-tab navigation system:
- **Home**: Central hub with Quick Add and today's items
- **Habits**: All habits with filtering and management
- **Tasks**: Task list with priority indicators
- **Medications**: Medication schedule with "Take Now" feature
- **Progress**: 7-day history with search and filters

Each tab maintains its own state and dynamically updates the Quick Add button text.

### Core Architectural Patterns

1. **Protocol-Oriented Design**:
   - `ItemProtocol` unifies different data types for display
   - Enables polymorphic list rendering

2. **View Composition**:
   - Small, focused view components
   - Heavy use of computed properties for derived state
   - Extracted subviews for readability

3. **Thread Safety**:
   - All SwiftData models marked with `@MainActor`
   - Async operations use `Task { @MainActor in }` pattern
   - Prevents race conditions in UI updates

4. **Form Management**:
   - Forms support create and edit modes
   - Auto-focus on primary fields
   - Validation before save
   - Form counters ensure proper reset between uses
   - Automatic cleanup on cancel

5. **Repetition Algorithms**:
   - Daily: `daysDifference % interval == 0`
   - Weekly: Check specific weekdays + week interval
   - Monthly: Check day of month + month interval
   - Custom: Specific days array

## Critical Implementation Details

### Habit Repetition System
The app uses an innovative approach where habits are stored once in the database but instances are generated dynamically based on repetition rules. This prevents database bloat and enables complex repetition patterns.

### Medication "Take Now" Feature
Medications support both scheduled doses and unscheduled "take now" doses, critical for as-needed medications like blood pressure pills. Unscheduled doses are tracked separately with timestamps.

### State Persistence
- Uses SwiftData for all persistent state
- Habit and medication completion states stored in separate instance tables
- Timestamps track when actions were taken
- Currently configured for in-memory storage during development

### Performance Optimizations
- 3-day window for habit/medication generation
- LazyVStack for efficient list rendering
- Computed properties for derived values
- Minimal database queries
- View identity management prevents unnecessary re-renders

### Data Flow
1. SwiftData serves as the single source of truth
2. Views observe model changes via `@Query`
3. Dynamic instances generated on-demand
4. State updates trigger automatic UI refresh
5. Cross-tab state synchronization via shared model context

### Spanish Development Context
The original development (see prompts.md) was done in Spanish. Key Spanish terms in documentation:
- "Hábitos" = Habits
- "Tareas" = Tasks  
- "Medicamentos" = Medications

## Known Patterns and Conventions

1. **Always use design system tokens** - No hardcoded colors, spacing, or fonts
2. **Maintain form state consistency** - Reset on cancel, validate on save
3. **Use proper SwiftData annotations** - `@Model` for persistence, `@MainActor` for thread safety
4. **Follow animation conventions** - 0.3s duration for most transitions
5. **Implement proper error handling** - Though TODOs exist for user alerts
6. **Test on multiple screen sizes** - App should work on all iPhones/iPads
7. **Use semantic SF Symbols** - Ensure icons convey meaning
8. **Preserve Spanish comments** - Original development context

## Current Limitations and TODOs

1. **In-memory storage** - Temporary solution to avoid migration issues
2. **Missing user alerts** - Error messages print to console only
3. **Limited test coverage** - Minimal unit tests currently
4. **No analytics** - User behavior tracking not implemented
5. **Basic accessibility** - VoiceOver support incomplete

## Future Considerations

The codebase is designed to be portable to Android (as noted in prompts.md). The centralized design system and clear separation of concerns facilitate this future migration.

### Migration to Production
- Switch from in-memory to persistent storage
- Implement proper data migration strategy
- Add comprehensive error handling with user alerts
- Complete accessibility features
- Add analytics for user behavior tracking

## Reference Documentation

### Apple Developer Resources
- **Design Tips**: https://developer.apple.com/design/tips/
  - Essential guidelines for creating great user experiences
  - Best practices for iOS app design
  
- **Swift Documentation**: https://developer.apple.com/documentation/swift
  - Official Swift language reference
  - API documentation for all Swift frameworks
  
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/
  - Comprehensive design principles for iOS
  - Platform-specific UI patterns and conventions
  - Accessibility guidelines and requirements