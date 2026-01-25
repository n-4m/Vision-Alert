# 🚨 Vision Alert (Flutter)

## 📖 Project Description

This is a **real-time collision warning** mobile application developed with Flutter, designed to assist visually impaired users in navigating more safely. The app utilizes the device's camera combined with the **YOLOv8** machine learning model to detect obstacles and provide immediate voice warnings in Vietnamese as soon as a potential collision risk is detected.

## 🔑 Key Features

### Real-time Object Detection

- Uses the **YOLOv8 (TensorFlow Lite)** model optimized for mobile devices.
- Automatically detects and classifies various types of objects within the camera frame.

### Intelligent Warning System

- **Distance Estimation:** Based on changes in Bounding Box size to determine if an object is approaching.
- **Danger Zone Identification:** Focuses warnings only on objects located in the central area (the user's direction of movement).
- **Voice Warning (TTS):** Plays clear audio warnings in Vietnamese: _"Cẩn thận, có vật cản phía trước"_ (Be careful, obstacle ahead).
- **Haptic Feedback:** Triggers device vibration to provide an immediate tactile alert, ensuring the user is warned even in noisy environments.
- **Cooldown Mechanism:** Prevents warnings from repeating too quickly to avoid overwhelming the user.

### Performance & Architecture

- **On-device Processing:** All AI processing is performed directly on the phone, requiring no internet connection.
- **MVVM Architecture:** Uses the Clean Architecture (Model-View-ViewModel) design pattern for easy maintenance and source code scalability.

## 🧠 Technologies

- **Framework:** Flutter (Dart)
- **AI/ML:** TensorFlow Lite, YOLOv8
- **Plugins:** Camera Plugin, Flutter TTS (Text To Speech)
- **Architecture:** MVVM Pattern (BaseViewModel)

## 🔍 Collision Warning Logic

The system only triggers a warning when the following safety conditions are met:

1.  **Confidence ≥ 0.5:** The detection confidence level reaches over 50%.
2.  **Approaching:** The object's bounding box area is increasing (the object is moving closer to the camera).
3.  **Central Region:** The object is located within the camera's central observation zone.
4.  **Cooldown elapsed:** The resting period between warnings has passed.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK version: `>= 3.x`
- Physical Android device (required to run the camera and TFLite processing)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/n-4m/Vision-Alert.git
    ```

2.  **Navigate to the project directory:**

    ```bash
    cd Vision-Alert
    ```

3.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

4.  **Run the application:**

    ```bash
    flutter run
    ```

## 📸 Screen Shots

<div align="center">
  <img src="https://github.com/user-attachments/assets/95e8b234-5174-42ae-b02f-69f62b6b79e8" width="300" />
  <img src="https://github.com/user-attachments/assets/d0608ace-8aff-465c-a336-99dc501c70aa" width="300" />
  <img src="https://github.com/user-attachments/assets/8dd518dc-06e2-4c9f-b56f-4f39c0c1d2b5" width="300" />
  <img src="https://github.com/user-attachments/assets/0fcbcd74-f3b7-4b09-8a11-78da8706f101" width="300" />
</div>

## ⚠️ Limitations

- Current distance estimation is relative, based on image size.
- Depth sensors are not yet supported.
- Performance depends on the hardware configuration of each specific device.

## 👨‍💻 Author

**Developed by n-4m**  
_Purpose: Academic project supporting the community._
