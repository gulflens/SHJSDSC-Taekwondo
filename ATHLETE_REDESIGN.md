# SSDC Taekwondo — Athlete Module Redesign Instructions

## ROLE

You are acting as:

- Senior Apple Product Designer
- Senior iOS Architect
- Elite Sports Management Platform Designer
- SwiftUI Expert
- Government Sports Systems UX Specialist

Your task is to redesign and expand the athlete profile module for:

SSDC Taekwondo

This is a UAE government-sponsored taekwondo club management platform.

The final result must feel like:

- UAE Government sports system
- Olympic federation platform
- Apple-quality product
- Premium native iOS app
- Professional athlete management console

DO NOT GENERATE:
- Generic CRUD forms
- Simple dashboards
- Web-style admin panels
- Android-style layouts
- Flat enterprise UI
- Gaming UI

The final UI must visually match the attached design reference quality exactly.

---

# TECH STACK

- SwiftUI
- SwiftData
- Supabase
- iPhone + iPad
- Light + Dark Mode
- iPad Landscape Optimized

Architecture:
- MVVM
- Modular components
- Reusable design system
- Production-ready structure

---

# DESIGN LANGUAGE

## VISUAL STYLE

The UI must feel:

- Native Apple
- Premium
- Layered
- Professional
- Sports federation quality
- Information dense but clean

Use:

- Rounded cards
- Thin separators
- White surfaces
- Soft shadows
- SF Pro typography
- Blue accent colors
- Green performance indicators
- Premium spacing
- Smooth animations
- Native iOS interactions

Avoid:

- Heavy gradients
- Oversized components
- Excessive colors
- Generic charts
- Flat boring layouts

---

# ATHLETE PROFILE STRUCTURE

## HEADER SECTION

The athlete profile header must contain:

### LEFT SIDE
- Large athlete photo
- Edit photo button

### RIGHT SIDE
- Athlete full name EN
- Athlete full name AR
- Verification badge
- Metadata chips:
  - Gender
  - Age
  - Nationality
- Federation IDs
- Emirates ID
- Passport Number
- Blood Group

### STATUS BADGES
- Squad badge
- Weight category badge
- Belt badge

The visual hierarchy should match premium sports platforms.

---

# TOP NAVIGATION

Use horizontal segmented navigation tabs:

- Overview
- Performance
- Attendance
- Competitions
- Medical
- Documents
- Coach Notes
- More

Tabs must:
- Animate smoothly
- Feel native
- Use subtle active indicators
- Work on iPhone and iPad

---

# ATHLETE DATA MODEL

## CORE PROFILE

Create scalable athlete models supporting:

- Beginner athletes
- Development athletes
- Elite athletes
- National team athletes
- Olympic pathway athletes

### Required fields

```swift
fullNameEN
fullNameAR
dateOfBirth
gender
nationality
emiratesID
passportNumber
federationID
worldTaekwondoID
athletePhoto
belt
beltLevel
weightCategory
ageCategory
dominantLeg
squad
branch
coach
bloodGroup
```

## PARENT / GUARDIAN MODULE

Required fields:

- fatherName
- motherName
- guardianName
- relationship
- mobileNumber
- secondaryMobile
- email
- emergencyContact

## PERFORMANCE MODULE

Create graph-ready historical data.

Fields:

- speed
- power
- endurance
- flexibility
- reactionTime
- accuracy
- fitnessScore
- sparringScore
- coachEvaluation

Support:

- Trend analysis
- Historical progress
- Monthly comparison
- Coach assessments
- Visual analytics

## ATTENDANCE MODULE

Fields:

- attendanceRate
- sessionsCompleted
- lateArrivals
- excusedAbsence
- trainingHours
- sparringRounds

## COMPETITION MODULE

Fields:

- tournamentName
- location
- date
- division
- weight
- matchesWon
- matchesLost
- pointsScored
- penalties
- medal
- rankingPoints
- videoAnalysisLink

Include:

- Ranking progression
- Medal tracking
- Match history
- Federation statistics

## MEDICAL MODULE

Fields:

- allergies
- injuries
- medication
- insuranceExpiry
- recoveryStatus
- clearanceStatus
- doctorNotes

## DOCUMENTS MODULE

Store:

- Emirates ID
- Passport
- Insurance
- Consent forms
- Federation licenses
- Travel approvals

## COACH NOTES MODULE

Fields:

- technicalNotes
- tacticalNotes
- discipline
- mentalPerformance
- coachComments
- recommendations

---

# DASHBOARD CARDS

The Overview page must contain premium modular cards.

## Required Cards

### Athlete Summary

Contains:

- Belt
- Category
- Dominant leg
- Club
- Coach
- Branch
- Squad
- Circular progress chart

### Training This Week

Contains:

- Sessions
- Training hours
- Sparring rounds
- Fitness score

Use animated progress bars.

### Latest Performance

Contains:

- Fitness
- Speed
- Power
- Endurance
- Accuracy
- Reaction Time

### Upcoming Event

Contains:

- Tournament
- Date
- Location
- Weight category

### Current Rankings

Contains:

- Club ranking
- UAE ranking
- WT ranking
- Olympic pathway

### Recent Achievements

Contains:

- Medals
- Tournament names
- Dates

### Competition History Table

For iPad landscape:

- Tournament
- Date
- Location
- Weight
- Result
- Medal
- Ranking points

---

# iPHONE LAYOUT

## Requirements

- Single-column scrolling
- Sticky athlete header
- Compact cards
- Easy thumb reach
- Smooth animations

---

# iPAD LANDSCAPE LAYOUT

This must feel like a professional athlete management console.

## Requirements

- Multi-column layout
- Persistent sidebar
- Higher data density
- Wider cards
- Better analytics visibility
- Federation-style information management

Sidebar should contain:

- Dashboard
- Athletes
- Coaches
- Attendance
- Competitions
- Messaging
- Reports
- Video Analysis
- Settings

---

# DARK MODE

Create premium layered dark mode.

Requirements:

- Not pure black
- Elevated cards
- Rich depth
- Soft contrast
- Premium shadows
- Blue accents preserved
- Green metrics preserved

---

# COMPONENTS

Create reusable SwiftUI components:

- AthleteProfileView
- AthleteHeaderView
- AthleteOverviewCard
- PerformanceCard
- AttendanceCard
- CompetitionCard
- MedicalCard
- RankingCard
- AchievementCard
- TrainingProgressView
- ProfileMetadataChip
- FederationBadgeView

---

# PERFORMANCE REQUIREMENTS

The app must:

- Handle thousands of athletes
- Load smoothly
- Use async image loading
- Optimize scrolling performance
- Use lazy containers where needed
- Support offline-friendly caching

---

# UX QUALITY TARGET

The final result should feel inspired by:

- Apple Fitness
- 365Scores
- Olympic federation systems
- FIFA player management systems

BUT fully adapted for:

- Taekwondo
- UAE sports culture
- Government-sponsored athlete development

---

# IMPORTANT

DO NOT:

- Simplify the design
- Replace cards with forms
- Remove hierarchy
- Use generic placeholders
- Use low-quality spacing

The final output must look production-ready and premium.

Proceed step-by-step professionally.
