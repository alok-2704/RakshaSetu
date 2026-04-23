# RakshaSetu 🚨

## AI-Powered Emergency Response Platform

RakshaSetu is an intelligent emergency response platform designed to help organizations report, manage, and respond to emergencies faster and more effectively.

The current prototype is demonstrated in a campus environment, but the system is built to integrate with any organization such as colleges, offices, factories, hospitals, malls, warehouses, and residential communities.

---

## Problem Statement

Many organizations face delays during emergencies due to:

- Slow reporting
- Unclear incident details
- Poor coordination
- No smart prioritization system

Small but urgent incidents often depend unnecessarily on external emergency services.

RakshaSetu solves this by enabling fast internal emergency response with AI-assisted decision making.

---

## Key Features

### User Side
- Raise emergency alerts instantly
- Fire / Medical / Security alerts
- Voice SOS input
- Real-time status updates
- AI-generated safety guidance

### Admin Side
- Live responder dashboard
- Accept / Resolve alerts
- Real-time alert tracking
- AI-generated severity, priority, and action insights

### Platform Features
- Firebase Authentication
- Firestore Realtime Database
- Push Notifications
- Multi-role login system
- Scalable architecture for any organization

---

## Tech Stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Groq AI API

---

## Demo Credentials

### User Login
Email: user@demo.com  
Password: 123456

### Fire Department
Email: fire@demo.com  
Password: 123456

### Medical Department
Email: medical@demo.com  
Password: 123456

### Security Department
Email: security@demo.com  
Password: 123456

---

## Run Locally

```bash
flutter pub get
flutter run --dart-define=GROQ_API_KEY=YOUR_KEY

Important Note

If no AI key is provided, some AI features may run in fallback mode.