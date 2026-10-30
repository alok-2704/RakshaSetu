# RakshaSetu 🚨

## AI-Powered Emergency Response Platform

RakshaSetu is an intelligent emergency response platform designed to help organizations report, manage, and respond to emergencies faster and more effectively.

The current prototype is demonstrated in a campus environment, but the system is designed to be adaptable to organizations such as colleges, offices, factories, hospitals, malls, warehouses, and residential communities.

---

## Problem Statement

Many organizations face delays during emergencies due to:

- Slow incident reporting
- Unclear incident details
- Poor coordination between response teams
- Lack of smart incident prioritization

Small but urgent incidents may depend unnecessarily on external emergency services when an internal response team could provide the first level of assistance.

RakshaSetu addresses this by enabling structured internal emergency reporting and AI-assisted decision-making.

---

## Key Features

### User Side

- Raise emergency alerts instantly.
- Select Fire, Medical, Security, Hazard / Accident, or Violence / Harassment.
- Voice-based incident description using speech recognition.
- View active alerts and recent activity.
- Receive AI-generated safety guidance.

### Admin Side

- Department-specific response dashboards.
- Review incoming emergency alerts.
- Accept and resolve alerts.
- View active alerts and incident history.
- AI-generated severity, priority, and recommended action insights.

### Platform Features

- Firebase Authentication
- Cloud Firestore database
- Multi-role login system
- Department-specific dashboards
- Groq AI API integration
- Firebase Functions scaffold for production push notifications
- Scalable architecture designed for different organizational environments

---

## Demo Credentials

Use the following accounts to explore the different roles and department dashboards.

### Student / User Login

| Field | Credentials |
|---|---|
| Email | student@demo.com |
| Password | `student1` |

### Department Admin Logins

| Department | Email | Password |
|---|---|---|
| Fire | fire@demo.com | `123456` |
| Medical | medical@demo.com | `789101` |
| Security | security@demo.com | `654321` |
| Accident | accident@demo.com | `accident` |
| Violence | violence@demo.com | `violence` |

**Note:** These are demonstration credentials intended for testing the prototype. Do not use them for real organizational accounts or production deployment.

---

## Tech Stack

- **Frontend:** Flutter
- **Programming Language:** Dart
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Notifications:** Firebase Cloud Messaging
- **Serverless Backend:** Firebase Functions scaffold
- **AI Integration:** Groq AI API
- **Speech Recognition:** speech_to_text

---

## Run Locally

### 1. Clone the repository

```bash
git clone YOUR_REPOSITORY_URL
cd RakshaSetu
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the Groq API key

Provide your Groq API key using the project's configured environment or build-time configuration.

```bash
flutter run --dart-define=GROQ_API_KEY=YOUR_KEY
```

### 4. Run the application

```bash
flutter run
```

**Important:** If no valid AI API key is provided, some AI features may operate in fallback mode or display a connection error.



---

## Future Scope

- Verified real-time push notification delivery.
- Responder acknowledgement and live status tracking.
- Secure backend integration for AI requests.
- Permanent incident evidence storage.
- Multilingual support.
- Expansion to multiple organizations with separate administrative access.

---

## Project Objective

RakshaSetu aims to make emergency reporting more structured, improve internal coordination, and provide useful AI-assisted insights so that authorized response teams can review incidents with better information.

**RakshaSetu – Your Safety, Our Priority.**
