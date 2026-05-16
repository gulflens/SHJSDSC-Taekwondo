# SSDC Taekwondo — Coach Profile Module Instructions

## ROLE

You are acting as:

- Senior Apple Product Designer
- Senior iOS Architect
- Elite Sports Federation System Designer
- Sports Operations UX Specialist
- SwiftUI Expert

Your task is to create a professional Coach Profile module matching the exact design language and quality level of the athlete profile system.

The Coach Profile must visually feel part of the same ecosystem as the athlete module.

IMPORTANT:
The Coach Profile UI must look almost identical in visual quality, spacing, hierarchy, and structure to the athlete profile reference.

This is NOT a staff HR profile.

This is a professional:
- Olympic-level coaching profile
- Government sports management profile
- Elite athlete development management system

---

# PLATFORM

App:
SSDC Taekwondo

Technology:
- SwiftUI
- SwiftData
- Supabase
- iPhone + iPad
- Light + Dark Mode

Architecture:
- MVVM
- Modular reusable components
- Production-ready
- Federation-scalable

---

# VISUAL DESIGN LANGUAGE

The UI must feel:

- Native Apple
- Government-level
- Olympic federation quality
- Premium sports management platform
- Clean and layered
- Information-dense but elegant

Use:
- Rounded cards
- White layered surfaces
- Thin separators
- Soft shadows
- SF Pro typography
- Blue accent colors
- Green performance indicators
- Smooth animations
- Premium spacing

DO NOT:
- Use generic employee management UI
- Use boring tables everywhere
- Use web admin panel design
- Use Android design patterns
- Use oversized empty layouts

---

# COACH PROFILE STRUCTURE

## HEADER SECTION

The coach header must visually mirror the athlete profile header.

### LEFT SIDE
- Large coach profile photo
- Edit photo button

### RIGHT SIDE
- Full name EN
- Full name AR
- Verification badge
- Nationality
- Coaching level
- Years of experience
- Federation certification badges

### STATUS BADGES
- Head Coach
- National Coach
- Elite Team
- Sparring Coach
- Technical Coach
- Olympic Program

### ADDITIONAL INFO
- UAE Federation ID
- WT Coach ID
- Emirates ID
- Passport number
- Blood group
- Assigned branch

---

# TOP NAVIGATION

Horizontal tab navigation:

- Overview
- Athletes
- Performance
- Attendance
- Competitions
- Certifications
- Reports
- More

Must:
- Animate smoothly
- Feel native to iOS
- Match athlete profile tabs exactly

---

# COACH DATA MODEL

## CORE PROFILE

Required fields:

```swift
fullNameEN
fullNameAR
coachPhoto
dateOfBirth
gender
nationality
mobileNumber
email
emiratesID
passportNumber
federationCoachID
worldTaekwondoCoachID
bloodGroup
branch
yearsOfExperience
joinedDate
employmentStatus
role
specialization
```

## COACHING INFORMATION

Fields:

- coachLevel
- licenseLevel
- specialization
- assignedTeams
- assignedBranches
- technicalLevel
- sparringLevel
- poomsaeLevel
- fitnessLevel
- olympicProgramStatus
- nationalTeamStatus

## CERTIFICATIONS MODULE

Store:

- kukkiwonCertificates
- wtCertificates
- uaeFederationCertificates
- firstAidCertificate
- safeguardingCertificate
- strengthConditioningCertificates
- expiryDates
- verificationStatus

Include:

- Certificate previews
- Expiry tracking
- Renewal alerts
- Verification badges

## ATHLETE MANAGEMENT MODULE

Coach profile must display:

- Total athletes
- Elite athletes
- National team athletes
- Olympic pathway athletes
- Active athletes
- Injured athletes

Include:

- Athlete assignment overview
- Performance impact
- Athlete progression

## PERFORMANCE ANALYTICS

Fields:

- athleteImprovementRate
- competitionWinRate
- medalCount
- attendanceImpact
- promotionSuccessRate
- disciplineScore
- parentSatisfaction
- coachPerformanceScore

Support:

- Monthly trends
- Historical graphs
- Coach rankings
- Federation evaluations

## ATTENDANCE & OPERATIONS

Track:

- sessionsConducted
- missedSessions
- lateArrivals
- trainingHours
- monthlySchedule
- eventParticipation
- campParticipation

## COMPETITION MANAGEMENT

Track:

- tournamentsManaged
- athletesCompeted
- goldMedals
- silverMedals
- bronzeMedals
- teamRankings
- internationalParticipation

Include:

- Match analytics
- Coach impact metrics
- Competition history

## REPORTS MODULE

Coach profile should support:

- Athlete evaluations
- Belt recommendations
- Discipline reports
- Injury reports
- Performance reports
- Federation reports

Include:

- Pending approvals
- Submitted reports
- Approval status

## COMMUNICATION MODULE

Track:

- Parent communications
- Athlete meetings
- Internal coach notes
- Announcements
- Team discussions

---

# OVERVIEW DASHBOARD CARDS

## Required Cards

### Coach Summary

Contains:

- Role
- Experience
- Branch
- Teams
- Certifications
- Active athletes

### Coaching Performance

Contains:

- Win rate
- Athlete improvement
- Medal count
- Attendance impact

Use:

- Animated progress bars
- Trend indicators

### Team Overview

Contains:

- Total athletes
- Elite athletes
- National athletes
- Injured athletes

### Upcoming Events

Contains:

- Tournaments
- Camps
- Federation meetings
- Belt tests

### Certifications

Contains:

- Active certifications
- Expiry warnings
- Renewal progress

### Recent Achievements

Contains:

- Team medals
- Athlete promotions
- Federation recognitions

### Coach Rankings

Contains:

- Internal club ranking
- UAE federation ranking
- WT recognition level

---

# iPHONE LAYOUT

Requirements:

- Single-column scrolling
- Compact modular cards
- Sticky header
- Thumb-friendly navigation
- Smooth transitions

---

# iPAD LANDSCAPE LAYOUT

This must feel like a professional federation coaching console.

Requirements:

- Persistent sidebar
- Multi-column layout
- Higher information density
- Wider analytics cards
- Coach operational overview

Sidebar sections:

- Dashboard
- Athletes
- Coaches
- Attendance
- Competitions
- Reports
- Messaging
- Video Analysis
- Settings

---

# DARK MODE

Create premium layered dark mode.

Requirements:

- Rich depth
- Elevated cards
- Not pure black
- Premium contrast
- Blue accents preserved
- Green analytics preserved

---

# REUSABLE COMPONENTS

Create reusable SwiftUI components:

- CoachProfileView
- CoachHeaderView
- CoachOverviewCard
- CoachPerformanceCard
- TeamOverviewCard
- CertificationCard
- CompetitionAnalyticsCard
- CoachRankingCard
- CoachAchievementCard
- CoachScheduleCard
- CoachMetadataChip

---

# UX TARGET

The final result should feel inspired by:

- Apple Fitness
- FIFA coaching systems
- Olympic federation platforms
- Professional sports management systems

BUT adapted specifically for:

- UAE government sports clubs
- Taekwondo operations
- National athlete development

---

# IMPORTANT

DO NOT:

- Simplify the UI
- Use generic HR layouts
- Use boring forms
- Remove visual hierarchy
- Use basic cards only

The result must feel:

- Operational
- Premium
- Government-grade
- Federation-level
- Apple-quality

Proceed step-by-step professionally.
