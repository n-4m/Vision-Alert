# 🚨 Vision Alert (Flutter)

## 📖 Project Description

Đây là ứng dụng di động **cảnh báo va chạm thời gian thực** được phát triển bằng Flutter, nhằm hỗ trợ người khiếm thị di chuyển an toàn hơn. Ứng dụng sử dụng camera của thiết bị kết hợp với mô hình học máy **YOLOv8** để nhận diện vật cản và đưa ra cảnh báo bằng giọng nói tiếng Việt ngay khi phát hiện nguy cơ va chạm tiềm ẩn.

## 🔑 Key Features

### Nhận diện vật thể thời gian thực

- Sử dụng mô hình **YOLOv8 (TensorFlow Lite)** tối ưu hóa cho di động.
- Tự động nhận diện và phân loại nhiều loại vật thể khác nhau trong khung hình camera.

### Hệ thống cảnh báo thông minh

- **Ước lượng khoảng cách:** Dựa trên sự thay đổi kích thước của Bounding Box để xác định vật thể đang tiến lại gần.
- **Xác định vùng nguy hiểm:** Chỉ tập trung cảnh báo các vật thể nằm ở khu vực trung tâm (hướng di chuyển của người dùng).
- **Cảnh báo giọng nói (TTS):** Phát âm thanh cảnh báo bằng tiếng Việt rõ ràng: _"Cẩn thận, có vật cản phía trước"_.
- **Cơ chế Cooldown:** Ngăn chặn việc lặp lại cảnh báo quá nhanh gây nhiễu cho người dùng.

### Hiệu suất & Kiến trúc

- **On-device Processing:** Mọi thao tác xử lý AI đều thực hiện trực tiếp trên điện thoại, không cần kết nối internet.
- **MVVM Architecture:** Sử dụng mô hình thiết kế Clean Architecture (Model-View-ViewModel) để dễ dàng bảo trì và mở rộng mã nguồn.

## 🧠 Technologies

- **Framework:** Flutter (Dart)
- **AI/ML:** TensorFlow Lite, YOLOv8
- **Plugins:** Camera Plugin, Flutter TTS (Text To Speech)
- **Architecture:** MVVM Pattern (BaseViewModel)

## 🔍 Collision Warning Logic

Hệ thống chỉ kích hoạt cảnh báo khi hội đủ các điều kiện an toàn sau:

1.  **Confidence ≥ 0.5:** Độ tin cậy của việc nhận diện đạt trên 50%.
2.  **Approaching:** Diện tích bounding box của vật thể đang tăng dần (vật thể đang tiến gần camera).
3.  **Central Region:** Vật thể nằm trong vùng quan sát trọng tâm của camera.
4.  **Cooldown elapsed:** Đã qua khoảng thời gian nghỉ giữa các lần cảnh báo.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK version: `>= 3.x`
- Thiết bị Android thật (để chạy camera và xử lý TFLite)

### Installation

1.  **Clone the repository:**

    ```bash
    git clone [https://github.com/n-4m/Vision-Alert.git](https://github.com/n-4m/Vision-Alert.git)
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
(https://github.com/user-attachments/assets/d0608ace-8aff-465c-a336-99dc501c70aa)
https://github.com/user-attachments/assets/8dd518dc-06e2-4c9f-b56f-4f39c0c1d2b5)
https://github.com/user-attachments/assets/0fcbcd74-f3b7-4b09-8a11-78da8706f101)

    
  <img src="https://via.placeholder.com/300x600?text=Detection+Alert" width="300" />
</div>

## ⚠️ Limitations

- Việc ước lượng khoảng cách hiện tại chỉ ở mức tương đối dựa trên kích thước hình ảnh.
- Chưa hỗ trợ cảm biến chiều sâu (Depth sensor).
- Hiệu năng phụ thuộc vào cấu hình phần cứng của từng thiết bị.

## 👨‍💻 Author

**Phát triển bởi n-4m**  
_Mục đích: Đồ án học thuật hỗ trợ cộng đồng._
