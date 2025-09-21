
# goodPace 好腳步
![appstore](https://hackmd.io/_uploads/HJqGPvNmgx.png)
## Team Members
* 1112914 宋冠穎
* 1112970 潘振業
* 1112937 范嘉和
* 1112955 薛博徽

## Purpose
1. Tutorials
To teach people how to run in a right way.
2. Pass Time
To pass time.
3. Improve Health
To strengthen body and improve health.

## APP Interface And Functions
### Home Page
![Home Page](https://hackmd.io/_uploads/BkLTPvEmgx.png)
#### Weather
* Feature:
    * Shows the weather in your area.
* Reason:
    * Understand the weather to decide whether to go out for exercise.
#### Calendar
* Feature:
    * Display exercise log and notes.
* Reason:
    * Maintain regular exercise.
#### Workout Overview & Exercise History
* Feature:
    * Calculating exercise data.
    * Record recent exercise status.

### Recording Page
![Recording Page](https://hackmd.io/_uploads/BkfIuwVmll.png)
#### Exercise Recording
* Feature:
    * Real-time recording of time, distance, speed, Heart rate, etc.
    * Display the GPS location.
* Reason:
    * Real-time tracking of sports status and data.
#### Frequency Guidance
* Feature:
    * Uses a metronome or music to guide stride frequency, with adjustable frequency.
* Reason:
    * Guides appropriate stride frequency to enhance exercise effectiveness.
#### Exercise Statistics
* Feature:
    * Detailed stats on exercise performance
* Reason:
    * Helps users understand their progress
#### Navigation
* Feature:
    * Guides outdoor routes
* Reason:
    * Prevents users from getting lost

### Teach Page
![Teach Page](https://hackmd.io/_uploads/rkGjdwN7xg.png)
#### Posture Correction
* Feature:
    * Reminds of key movement points.
* Reason:
    * Reduces the risk of sports injuries.
#### Movement Tutorials
* Feature:
    * Animated or video-based instruction
* Reason:
    * Prevents injuries

### Route Page
![Route Page](https://hackmd.io/_uploads/BkUqYvN7xe.png)
#### Route Recommendations
* Feature:
    * Suggests nearby quality routes
    * Filter by tags.
* Reason:
    * Encourages outdoor exercise

### Profile Page
![Profile Page](https://hackmd.io/_uploads/rJufKPVQll.png)
#### User profile
* Feature:
    * Display user data  and setting
#### GPX Navigation
* Feature:
    * Import GPX files for sports navigation.
* Reason:
    * Customize the routes
####  Wearable Devices
* Feature:
    * To connect a new device
* Reason:
    * To detect users’ heart rate

## Reference
- cupertino_icons
    - https://pub.dev/packages/cupertino_icons
- table_calendar
    - https://pub.dev/packages/table_calendar
- flutter_map
    - https://pub.dev/packages/flutter_map
- intl
    - https://pub.dev/packages/intl
- geolocator
    - https://pub.dev/packages/geolocator
- audioplayers
    - https://pub.dev/packages/audioplayers
- sqflite
    - https://pub.dev/packages/sqflite
    - https://ithelp.ithome.com.tw/articles/10227611
- webview_flutter
    - https://pub.dev/packages/webview_flutter
- image_picker
    - https://pub.dev/packages/image_picker
- image_picker
    - https://pub.dev/packages/image_picker
- shared_preferences
    - https://pub.dev/packages/shared_preferences
- file_picker
    - https://pub.dev/packages/file_picker
- xml
    - https://pub.dev/packages/xml
- path_provider
    - https://pub.dev/packages/path_provider
- url_launcher
    - https://pub.dev/packages/url_launcher
- flutter_phoenix
    - https://pub.dev/packages/flutter_phoenix
- http
    - https://pub.dev/packages/http
- gpx
    - https://pub.dev/packages/gpx
- rename_app
    - https://pub.dev/packages/rename_app
* 正確的跑步姿勢
    *  https://youtu.be/ZwOVfDu_bng?si=0_D69VFpNWK-41a_
* 超慢跑步頻練習
    * https://youtu.be/YO5wcZeDki4?si=KWLnq6nHsZFFqvjW
* 跑步前熱身運動
    * https://youtu.be/-fI2BPfeTHI?si=XTxDavDJxZjeDbhV
* 跑步後拉伸運動
    * https://youtu.be/N1K2WARIxV4?si=rhV41cnZ3v9Jb_v0
## Conclusion
In this project, we successfully developed a running app specifically designed for elderly users. The app focuses on simplicity, and usability, offering features. By considering the unique needs of older adults, we aim to encourage physical activity, improve health, and enhance their confidence while exercising. This project demonstrates how thoughtful design and technology can support active aging and promote a healthier lifestyle for seniors.

## 附錄
### 檔案劃分
* ==main.dart==
    * 顯示功能列與控制顯示畫面，其他檔案return對應widget
    * 下方列切換列表
    * 路線/運動/首頁/教學/使用者 
        * 使用者 -> 工具設定
        * 首頁(開始運動) j 運動
* main_page.dart
    * 運動紀錄總覽
* profile.dart
    * 用戶資料 
    * 跑步設定
    * GPX
    * 穿戴設備
    * 通用設定
    * 關於 APP
* record.dart=
    * 即時運動追蹤
    * 地圖
    * 時間記錄
    * 步頻
* route.dart
    * 推薦路線
    * 彈出頁面顯示詳細資料
* teach.dart
    * 教學文章/影片列表
    * 彈出頁面顯示詳細資料
* ./db
    資料庫相關程式
### 資料庫規劃
* user
    * name
        * data type:string
    * userID
        * data type:string
    * password
        * data type:string
    * photo
        * data type:string (存檔案路徑)
    * height
        * data type:double(cm)
    * weight
        * data type:double(kg)
    * cadence
        * data type:int(步頻:bpm)
* teachData
    * teachID
        * data type:string
    * title
        * data type: string
    * videoUrl
        * data type: string
* runRecord
    * recordID
        * data type:string
    * userID
        * data type:string
    * recordFile
        * data type:string (存檔案路徑、.gpx)
