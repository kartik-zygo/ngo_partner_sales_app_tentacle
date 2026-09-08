# NGO Partner Sales App

A production-style Flutter app for NGO ecosystem operations with two complete roles:

- Sales Team
- Admin

The app is fully local/mock driven and demonstrates clean layered architecture, BLoC state management, dependency injection, and role-aware guarded UI flows.

## Tech Stack

- flutter_bloc + bloc
- equatable
- get_it
- google_fonts
- intl

## Project Structure

The app follows a layered + feature-driven structure:

```text
lib/
	core/
		constants/
		theme/
		utils/
		widgets/
	data/
		datasources/
		models/
		repositories/
	domain/
		entities/
		repositories/
		usecases/
	presentation/
		blocs/
			auth/
			dashboard/
			leads/
			tasks/
			notifications/
			admin_team/
			admin_services/
			admin_reports/
		pages/
			splash/
			auth/
			sales/
			admin/
		widgets/
	injection_container.dart
	main.dart
```

## Setup And Run

1. Ensure Flutter SDK is installed and on PATH.
2. Install dependencies:

```bash
flutter pub get
```

3. Run static checks:

```bash
flutter analyze
```

4. Run app:

```bash
flutter run
```

## Test Credentials

- Sales: sales1@ngo.com / sales123
- Admin: admin@ngo.com / admin123

## Architecture Overview

- Domain layer owns entities, repository interfaces, and use-cases.
- Data layer contains mock local datasource with seeded data and repository implementations.
- Presentation layer uses BLoC per feature and never directly talks to datasource.
- Dependency injection uses get_it for all repositories, use-cases, and blocs.
- Role-aware entry flow:
	- Splash -> auth session check
	- Login if no session
	- Sales/Admin shell based on role

## Feature Map By Role

### Shared / Entry

- Splash screen
- Login with role resolution
- Role-guarded shell access
- Logout flow
- In-app notifications module

### Sales Team

- Dashboard:
	- KPI cards
	- recent activity timeline
	- quick actions
- Leads:
	- search/filter/sort
	- user app source filter chip
	- add/edit/delete
	- detail page with notes timeline
	- user app context panel (source, user identity, service, queued update count)
	- activity history
	- status update actions
	- follow-up scheduler
- Follow-ups & Tasks:
	- grouped by date sections
	- mark complete
	- reschedule
- Client Onboarding / Case Creation:
	- 4-step flow (details, services, docs, review)
	- submit creates case history entry
	- connectivity action panel per case:
		- request additional documents
		- mark review complete (case status sync)
		- push user app notification event
	- assigned support ticket queue actions (start/waiting/resolved)
- Profile:
	- profile card
	- settings shortcuts
	- notifications section

### Admin

- Dashboard:
	- team performance summary
	- pipeline overview
	- revenue summary toggle (weekly/monthly)
	- pending approvals metrics
	- integration health widget:
		- new user app leads today
		- unassigned user app leads
		- cases stuck in resubmit required
		- pending collaboration requests
- Lead Assignment Center:
	- unassigned vs assigned lists
	- assign/reassign leads
	- source badges + SLA timers for prioritization
	- assignment history stream
	- support queue actions (escalate, reassign to sales, close)
	- collaboration pipeline visibility with pending count
- Team Management:
	- list members
	- add/edit
	- deactivate/reactivate
	- performance snapshot fields
- Service Catalog Management:
	- list service packages
	- add/edit
	- enable/disable
- Approval Center:
	- pending requests
	- approve/reject actions
- Reports & Analytics:
	- date range filters
	- revenue records
	- mock export action
	- generated export history
- Admin Settings:
	- permission toggle controls (UI-level mock behavior)
	- admin notifications

## UX Notes

- Custom theme with strong visual tokens and Google Fonts
- Layered gradient backgrounds and glass-style cards
- Animated transitions and staggered list reveal
- Responsive behavior for phone + tablet layouts
- Snackbar feedback for key mutations
- Loading, empty, success/failure-aware states across major modules

## User App Connectivity Simulation

The mock datasource seeds end-to-end cross-app scenarios so the Sales/Admin app can behave as if it is connected to a separate NGO user app.

- User actions (service purchase, support tickets, collaboration requests) can create or update sales leads.
- Lead and case state transitions can sync back into user-facing case statuses.
- Document request and resubmission loops are tracked with rounds and history.
- Support tickets can be triaged by admin and worked by sales.
- Notification bridge queue stores outbound user app updates for delivery simulation.
