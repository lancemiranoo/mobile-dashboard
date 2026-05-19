# AGENTS.md

Project:
- Flutter mobile dashboard application

Stack:
- Flutter
- Dart
- Firebase
- Firestore
- Firebase Auth
- Firebase Cloud Messaging

Architecture:
- Clean Architecture
- Feature-first structure
- Repository pattern

State Management:
- Riverpod

Routing:
- GoRouter

Rules:
- No GetX
- No business logic inside widgets
- No direct Firestore access in UI layer
- All Firebase calls go through repositories

UI:
- Responsive layouts mandatory
- Tablet support required
- Dark mode support required

Performance:
- Paginate Firestore queries
- Avoid unnecessary rebuilds
- Use streams efficiently

AI contributors must follow:
- AGENTS.md
- .agents/*