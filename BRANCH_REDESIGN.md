# SSDC Taekwondo — Branch Management Module Instructions

## ROLE

You are acting as:

- Senior Apple Product Designer
- Senior iOS Architect
- Elite Sports Federation System Designer
- Government Sports Operations UX Specialist
- SwiftUI Expert

Your task is to create a premium Branch Management module for:

SSDC Taekwondo

The club contains:

- 1 Main Branch
- 3 Secondary Branches

The final result must visually match the same premium design language used in:
- Athlete Profile
- Coach Profile

This must feel like:
- UAE government sports platform
- Olympic federation management system
- Apple-quality native iOS application

DO NOT:
- Create generic branch lists
- Use boring admin dashboards
- Use flat enterprise layouts
- Use Android/web design patterns
- Create spreadsheet-looking UI

The final result must feel premium, operational, and federation-grade.

---

# TECH STACK

- SwiftUI
- SwiftData
- Supabase
- iPhone + iPad
- Light + Dark Mode
- Landscape optimized iPad support

Architecture:
- MVVM
- Reusable components
- Production-ready
- Scalable

---

# VISUAL DESIGN LANGUAGE

Use:
- White layered cards
- Rounded corners
- Soft shadows
- Thin separators
- Premium spacing
- SF Pro typography
- Blue accent colors
- Green performance indicators
- Native Apple interactions

The UI should feel:
- Information dense
- Operational
- Elegant
- Premium
- Fast
- Structured

Avoid:
- Oversized empty cards
- Heavy gradients
- Gaming UI
- Generic charts
- Basic tables only

---

# BRANCH MANAGEMENT STRUCTURE

The system contains:

## MAIN BRANCH
Abu Dhabi Main Branch

## SECONDARY BRANCHES
- Al Ain Branch
- Dubai Branch
- Sharjah Branch

The Main Branch acts as:
- Central management hub
- Head coach location
- Federation operations center
- Main athlete development center

Secondary branches report operationally to the main branch.

---

# BRANCH OVERVIEW SCREEN

Create a premium Branch Overview screen.

This screen must visually feel like:
- Multi-site operations console
- Federation branch management system
- National sports academy management platform

---

# iPHONE LAYOUT

## TOP HEADER

Contains:
- Page title: Branches
- Notification icon
- Back button

---

## HERO CARD

Large premium card showing:

```swift
Total Branches
Main Branches
Secondary Branches
Total Athletes
Total Coaches
Weekly Sessions
Monthly Events
```

Visual style:

- Premium blue gradient
- Layered glass-like effect
- White typography
- Soft depth
- Modern Apple feel

## BRANCH LIST

Each branch card must contain:

### Branch Image

Use modern building preview image.

### Branch Information

- Branch name
- City
- Status
- Main/Secondary badge

### Statistics

- totalAthletes
- totalCoaches
- sessionsPerWeek
- monthlyEvents

### Status Indicator

- Active
- Inactive
- Maintenance
- Tournament Mode

Use:

- Green status dot
- Premium metadata chips

## MAIN BRANCH CARD

The main branch card should feel visually dominant.

Include:

- Larger card size
- Highlight border
- Premium elevation
- Main Branch badge

Display:

- Athlete count
- Coaches
- Weekly sessions
- Internal events
- Federation meetings

---

# iPAD LANDSCAPE LAYOUT

This screen must feel like a real federation management console.

## SIDEBAR

Persistent sidebar containing:

- Dashboard
- Athletes
- Coaches
- Branches
- Attendance
- Sessions
- Competitions
- Events
- Messaging
- Reports
- Settings

## MAIN CONTENT AREA

The layout should use:

- Multi-column responsive layout
- Analytics cards
- Branch hierarchy visualization
- Operational summaries

## TOP ANALYTICS ROW

Cards showing:

- Total Branches
- Main Branches
- Secondary Branches
- Total Athletes
- Total Coaches
- Active Sessions

Use:

- Compact Apple-style analytics cards
- Small trend indicators
- Premium spacing

## BRANCH STRUCTURE VISUALIZATION

Create a visual hierarchy section.

Top:

- Abu Dhabi Main Branch

Connected below:

- Al Ain Branch
- Dubai Branch
- Sharjah Branch

Use:

- Elegant connection lines
- Modern organization chart feel
- Premium branch cards

Each branch node shows:

- branchName
- location
- athleteCount
- coachCount
- weeklySessions
- monthlyEvents
- status

## ANALYTICS SECTION

Create modular cards for:

### Athlete Distribution

Use:

- Donut chart
- Athlete percentage by branch

### Sessions This Week

Use:

- Minimal Apple-style bar chart

### Branch Performance

Table containing:

- attendanceRate
- athleteGrowth
- coachRating
- performanceScore

Include:

- Trend arrows
- Small performance indicators

## UPCOMING EVENTS SECTION

Display events across branches.

Each event card contains:

- eventName
- date
- branch
- eventType
- participantCount

Event types:

- Championship
- Belt Test
- Training Camp
- Workshop
- Federation Visit

Use:

- Compact event cards
- Color-coded tags

---

# BRANCH DETAIL SCREEN

When selecting a branch:

Create a premium detailed branch profile.

## BRANCH HEADER

Contains:

- Branch image/banner
- Branch name
- City
- Branch manager/head coach
- Active status
- Main/Secondary badge

## BRANCH STATISTICS

Show:

- athletes
- coaches
- sessions
- events
- attendanceRate
- promotionRate
- competitionWins
- monthlyGrowth

## BRANCH TABS

Horizontal navigation:

- Overview
- Athletes
- Coaches
- Sessions
- Competitions
- Reports
- More

## OVERVIEW CARDS

- Branch Summary
- Performance Metrics
- Upcoming Sessions
- Recent Achievements
- Athlete Growth
- Coach Overview
- Attendance Analytics

---

# DARK MODE

Create premium layered dark mode.

Requirements:

- Not pure black
- Elevated cards
- Rich contrast
- Soft lighting
- Blue accents preserved
- Green analytics preserved

---

# COMPONENTS

Create reusable SwiftUI components:

- BranchOverviewView
- BranchCard
- MainBranchCard
- BranchAnalyticsCard
- BranchHierarchyView
- BranchEventCard
- BranchPerformanceCard
- BranchSummaryCard
- BranchHeaderView
- BranchStatisticsView

---

# UX QUALITY TARGET

The final result should feel inspired by:

- Apple Fitness
- FIFA federation systems
- Olympic management dashboards
- Enterprise Apple dashboards

BUT adapted specifically for:

- Taekwondo
- UAE government sports clubs
- Multi-branch athlete development operations

---

# IMPORTANT

DO NOT:

- Simplify the UI
- Replace cards with generic lists
- Use basic admin tables
- Remove hierarchy
- Use low-quality spacing

The result must feel:

- Operational
- Federation-grade
- Premium
- Native iOS
- Apple-quality polished

Proceed step-by-step professionally.
