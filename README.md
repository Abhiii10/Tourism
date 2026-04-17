# 🌄 AI-Driven Rural Tourism App (Nepal)

## 📌 Overview

This project is a **Flutter-based mobile application** designed to promote **rural tourism in Nepal**, especially in underrepresented areas around Pokhara Valley.

The app focuses on solving key challenges:

* Low digital visibility of rural destinations
* Poor internet connectivity
* Language barriers between tourists and local hosts

---

## 🚀 Current Features (Implemented)

### ✅ Destination Browsing

* View curated rural destinations
* Explore cultural, natural, and local experiences

### ✅ Recommendation System

* Content-based recommendation logic
* Suggests destinations based on:

  * user interests
  * season
  * budget
  * travel preferences

### ✅ Offline-Friendly Data

* Uses local JSON datasets
* Works without constant internet

### ✅ Saved Places

* Users can save favorite destinations
* Stored locally using SQLite

### ✅ Map View

* Interactive map using OpenStreetMap (currently online tiles)

---

## 🧠 Research Component

This project includes a **content-based recommender system** implemented using:

* Python (data processing & experiments)
* Feature-based similarity (no heavy user data required)

This approach is suitable for **low-data rural environments**.

---

## ⚠️ Work in Progress / Future Features

The following features are part of the research scope but not fully implemented yet:

* 🔄 Offline map support (MBTiles)
* 🌐 Nepali ↔ English translation (on-device)
* 🤖 AI chatbot for travel assistance
* 🏡 Host-side listing management

---

## 🏗️ Tech Stack

### Mobile App

* Flutter
* Dart
* SQLite (sqflite)

### Data & AI

* Python
* Pandas
* Content-based filtering

### Maps

* OpenStreetMap (via flutter_map)

---

## 📁 Project Structure

```
Tourism/
│
├── app/                # Flutter mobile application
├── recommender/        # Recommendation logic (Python)
├── nlp/                # NLP & translation experiments
├── evaluation/         # Evaluation results
├── experiments/        # Research experiments
├── docs/               # Documentation
└── scripts/            # Utility scripts
```

---

## ▶️ How to Run the App

```bash
cd app
flutter pub get
flutter run
```

---

## 📊 Project Goal

To demonstrate how **AI + offline-first design** can improve:

* digital visibility of rural tourism
* accessibility in low-connectivity environments
* communication between tourists and local communities

---

## 🧑‍💻 Author

Abhishek Paudel
BSc (Hons) Computer Science

---

## 📌 Notes

This project is part of a **final year dissertation** and focuses on building a **practical prototype**, not a full commercial system.
