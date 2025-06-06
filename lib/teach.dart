import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// 移除： import 'package:youtube_parser/youtube_parser.dart'; // 不再需要這個套件

// 索引 5: 教學 - 動作展示與學習 (功能 4)
class TeachPage extends StatelessWidget {
  const TeachPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 模擬教學內容數據
    // 注意：這裡的 videoUrl 應該是原始的 YouTube 觀看頁面連結
    final mockTrainingItems = const [
      {
        'title': '正確的跑步姿勢',
        'subtitle': '觀看教學影片',
        'icon': Icons.accessibility_new,
        // *** 重要：請替換為真實的 YouTube 影片連結 ***
        'videoUrl': 'https://www.youtube.com/watch?v=ZwOVfDu_bng'
      },
      {
        'title': '超慢跑步頻練習',
        'subtitle': '學習如何找到適合的步頻',
        'icon': Icons.music_note,
        // *** 重要：請替換為真實的 YouTube 影片連結 ***
        'videoUrl': 'https://www.youtube.com/watch?v=YO5wcZeDki4'// 範例：班長布萊恩的影片
      },
      {
        'title': '跑步前熱身運動',
        'subtitle': '避免運動傷害',
        'icon': Icons.whatshot,
        // *** 重要：請替換為真實的 YouTube 影片連結 ***
        'videoUrl': 'https://www.youtube.com/watch?v=-fI2BPfeTHI'
      },
      {
        'title': '跑步後拉伸運動',
        'subtitle': '加速恢復',
        'icon': Icons.fitness_center,
        // *** 重要：請替換為真實的 YouTube 影片連結 ***
        'videoUrl': 'https://www.youtube.com/watch?v=N1K2WARIxV4'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '跑步技巧與教學',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...mockTrainingItems.map((item) => Card(
          // 教學項目卡片
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(item['icon'] as IconData?,
                color: Theme.of(context).primaryColor),
            // 使用主題 primaryColor
            title: Text(item['title']! as String,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text(item['subtitle']! as String,
                style: const TextStyle(fontSize: 16)),
            trailing: _HoverPlayButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(videoUrl: item['videoUrl'] as String),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VideoPlayerScreen(videoUrl: item['videoUrl'] as String),
                ),
              );
            },
          ),
        ))
            .toList(),
      ],
    );
  }
}

// 新增的互動播放按鈕 Widget
class _HoverPlayButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HoverPlayButton({required this.onTap});

  @override
  State<_HoverPlayButton> createState() => _HoverPlayButtonState();
}

class _HoverPlayButtonState extends State<_HoverPlayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? Colors.purple.withOpacity(0.2) : Colors.transparent,
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Icon(
            Icons.play_circle_fill,
            color: _isPressed ? Colors.purple : Theme.of(context).colorScheme.secondary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  String? _embedUrl; // 將嵌入網址儲存起來，方便後續判斷

  // 自行解析 YouTube 影片 ID 的函式
  String? _getYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  void initState() {
    super.initState();

    // 自行解析 YouTube 影片 ID
    final String? videoId = _getYouTubeVideoId(widget.videoUrl);

    if (videoId == null || videoId.isEmpty) {
      // 處理無法解析影片ID的情況，例如顯示錯誤訊息或返回
      print('無法解析 YouTube 影片 ID: ${widget.videoUrl}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('影片網址無效，請檢查。')),
        );
        Navigator.pop(context); // 返回上一頁
      });
      return;
    }

    // 構建 YouTube 嵌入網址
    // 正確的 YouTube 嵌入網址格式
    _embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=1&controls=0&modestbranding=1&rel=0';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
            // print('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            // 可以在這裡顯示錯誤訊息給用戶
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('載入影片時發生錯誤: ${error.description}')),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // 允許播放 YouTube 嵌入影片，並阻止跳轉到其他網站
            // 判斷是否為 YouTube 域名
            if (request.url.startsWith('https://www.youtube.com/embed/') ||
                request.url.startsWith('https://www.youtube.com/watch?v=') ||
                request.url.startsWith('https://m.youtube.com/') || // 考慮手機版連結
                request.url.startsWith('https://youtu.be/')) {
              return NavigationDecision.navigate;
            }
            print('阻止導航到: ${request.url}');
            return NavigationDecision.prevent; // 防止跳轉到其他網站
          },
        ),
      );

    // 只有在 _embedUrl 不為 null 時才載入請求
    if (_embedUrl != null) {
      _controller.loadRequest(Uri.parse(_embedUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_embedUrl == null) {
      // 如果無法解析影片ID，則不顯示 WebView，避免錯誤
      return Scaffold(
        appBar: AppBar(
          title: const Text('教學影片'),
        ),
        body: const Center(
          child: Text('無法播放影片，請確認影片網址。'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('教學影片'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}