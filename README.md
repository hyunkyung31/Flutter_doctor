# 🩺 Doctor App

AI 기반 관상동맥 협착 진단 결과를 의료진에게 제공하고,
환자 관리 및 협진을 지원하는 모바일 헬스케어 애플리케이션입니다.

## Key Features

- 🤖 AI Coronary Artery Stenosis Detection
- 📄 AI Diagnosis Report
- 👨‍⚕️ Patient Management
- 💬 Real-time Consultation
- 📅 Schedule Management
- 🔒 Secure Medical Data Protection

------ 

## ✨ Features

### 🤖 AI Diagnosis
- Coronary Artery Stenosis Detection
- Bounding Box (BBox) Visualization
- Grad-CAM Explainable AI
- AI Report (PDF)
- Examination History

### 👨‍⚕️ Patient Management
- Patient List
- Patient Search
- Recent Patients
- Examination History
- Memo & Voice Memo

### 💬 Collaboration
- Real-time Chat
- Consultation Request
- Calendar
- Todo Management
- Push Notification

### 🔒 Security
- JWT Authentication
- RBAC (Role-Based Access Control)
- Biometric Authentication
- Screen Capture Prevention
- Background Privacy Protection
- Re-authentication for Sensitive Data

---

## 🛠 Tech Stack

### Frontend
- Flutter
- Provider
- Dio

### Backend
- Django REST Framework
- FastAPI

### AI
- YOLO11
- InceptionV3
- Grad-CAM

### Database
- MySQL

### Authentication
- JWT
- Local Authentication
- Flutter Secure Storage

### Notification
- Firebase Cloud Messaging (FCM)

---

## 📂 Project Structure

```text
lib
├── core
│   ├── network
│   ├── theme
│   ├── widgets
│   └── utils
│
├── models
├── providers
├── services
├── routes
├── screens
│   ├── auth
│   ├── home
│   ├── patient
│   ├── diagnosis
│   ├── consultation
│   └── settings
│
└── main.dart
```
