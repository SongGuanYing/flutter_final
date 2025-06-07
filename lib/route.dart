import 'package:flutter/material.dart';

// 路線資料模型
class RouteData {
  final String id;
  final String name;
  final double distance;
  final int estimatedDuration; // 分鐘
  final String difficulty;
  final double elevation; // 海拔變化
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final String description;
  final String startPoint;
  final String endPoint;
  final List<String> highlights;
  final String surfaceType;
  final bool isLoop;
  final DateTime? lastUsed;

  RouteData({
    required this.id,
    required this.name,
    required this.distance,
    required this.estimatedDuration,
    required this.difficulty,
    required this.elevation,
    required this.tags,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.startPoint,
    required this.endPoint,
    required this.highlights,
    required this.surfaceType,
    required this.isLoop,
    this.lastUsed,
  });
}

// 索引 4: 路線 - 路線推薦與詳細資料
class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  String _selectedFilter = '全部';
  final List<String> _filterOptions = ['全部', '初學者', '中級', '進階', '環狀', '單程'];

  // 模擬推薦路線數據
  final List<RouteData> mockRoutes = [
    RouteData(
      id: '1',
      name: '公園環湖路線',
      distance: 3.0,
      estimatedDuration: 30,
      difficulty: '初學者',
      elevation: 15.0,
      tags: ['公園', '湖景', '平坦'],
      rating: 4.5,
      reviewCount: 128,
      description: '這條路線環繞美麗的湖泊，地勢平坦，適合初學者和想要輕鬆跑步的跑者。沿途風景優美，空氣清新。',
      startPoint: '公園南門',
      endPoint: '公園南門',
      highlights: ['湖景', '涼亭休息點', '飲水機', '廁所'],
      surfaceType: '柏油路面',
      isLoop: true,
    ),
    RouteData(
      id: '2',
      name: '河濱自行車道',
      distance: 5.2,
      estimatedDuration: 50,
      difficulty: '中級',
      elevation: 35.0,
      tags: ['河濱', '自然', '微坡'],
      rating: 4.2,
      reviewCount: 87,
      description: '沿著河濱的自行車道，有輕微坡度變化，適合中級跑者。途中可欣賞河景和城市天際線。',
      startPoint: '河濱公園入口',
      endPoint: '大橋下',
      highlights: ['河景', '橋樑景觀', '野鳥觀察', '健身設施'],
      surfaceType: '混合路面',
      isLoop: false,
    ),
    RouteData(
      id: '3',
      name: '山丘挑戰路線',
      distance: 4.8,
      estimatedDuration: 55,
      difficulty: '進階',
      elevation: 120.0,
      tags: ['山丘', '挑戰', '陡坡'],
      rating: 4.7,
      reviewCount: 45,
      description: '具有挑戰性的山丘路線，適合進階跑者。雖然辛苦但山頂風景絕佳，是訓練體能的好選擇。',
      startPoint: '山腳登山口',
      endPoint: '觀景台',
      highlights: ['山頂美景', '觀景台', '森林浴', '挑戰坡度'],
      surfaceType: '石板步道',
      isLoop: false,
    ),
  ];

  // 模擬已儲存路線數據
  final List<RouteData> mockSavedRoutes = [
    RouteData(
      id: 's1',
      name: '我家附近的路線 A',
      distance: 2.5,
      estimatedDuration: 25,
      difficulty: '初學者',
      elevation: 8.0,
      tags: ['住家附近', '熟悉'],
      rating: 4.0,
      reviewCount: 12,
      description: '我常跑的住家附近路線，熟悉安全，適合日常訓練。',
      startPoint: '家門口',
      endPoint: '社區公園',
      highlights: ['熟悉路線', '安全', '便利商店'],
      surfaceType: '柏油路面',
      isLoop: false,
      lastUsed: DateTime.now().subtract(Duration(days: 2)),
    ),
    RouteData(
      id: 's2',
      name: '學校操場路線',
      distance: 1.2,
      estimatedDuration: 12,
      difficulty: '初學者',
      elevation: 0.0,
      tags: ['操場', '標準', '平坦'],
      rating: 3.8,
      reviewCount: 8,
      description: '標準的400公尺操場，適合計時和間歇訓練。',
      startPoint: '操場入口',
      endPoint: '操場入口',
      highlights: ['標準跑道', '計時方便', '平坦無坡'],
      surfaceType: '跑道',
      isLoop: true,
      lastUsed: DateTime.now().subtract(Duration(days: 5)),
    ),
  ];

  List<RouteData> get filteredRoutes {
    if (_selectedFilter == '全部') return mockRoutes;
    if (_selectedFilter == '環狀') return mockRoutes.where((r) => r.isLoop).toList();
    if (_selectedFilter == '單程') return mockRoutes.where((r) => !r.isLoop).toList();
    return mockRoutes.where((r) => r.difficulty == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '跑步路線',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 篩選器
        _buildFilterSection(),
        const SizedBox(height: 20),

        // 路線推薦區塊
        _buildRecommendedRoutesSection(),
        const SizedBox(height: 20),

        // 已儲存路線區塊
        _buildSavedRoutesSection(),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('篩選路線', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _filterOptions.map((filter) =>
                  ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedRoutesSection() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('推薦路線', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: 重新載入推薦路線
                    print('重新載入推薦路線');
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('根據您的位置和喜好推薦的優質跑步路線：', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            ...filteredRoutes.map((route) => _buildRouteCard(route, false)).toList(),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 實現尋找更多推薦路線功能
                  print('尋找更多推薦路線!');
                },
                icon: const Icon(Icons.search),
                label: const Text('尋找更多路線'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRoutesSection() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('已儲存路線', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    // TODO: 管理已儲存路線
                    print('管理已儲存路線');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('管理'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...mockSavedRoutes.map((route) => _buildRouteCard(route, true)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteData route, bool isSaved) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => _showRouteDetails(route),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 路線名稱和評分
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isSaved) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text('${route.rating} (${route.reviewCount})'),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 基本資訊
              Row(
                children: [
                  _buildInfoChip(Icons.straighten, '${route.distance} km'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.access_time, '${route.estimatedDuration} 分鐘'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.trending_up, '${route.elevation.toInt()}m'),
                ],
              ),
              const SizedBox(height: 8),

              // 難度和類型
              Row(
                children: [
                  _buildDifficultyChip(route.difficulty),
                  const SizedBox(width: 8),
                  if (route.isLoop)
                    const Chip(
                      label: Text('環狀', style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  if (isSaved && route.lastUsed != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '上次使用: ${_formatDate(route.lastUsed!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // 標籤
              Wrap(
                spacing: 4.0,
                children: route.tags.take(3).map((tag) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 11)),
                    )
                ).toList(),
              ),

              // 動作按鈕
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRouteDetails(route),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('詳情'),
                  ),
                  if (!isSaved) ...[
                    TextButton.icon(
                      onPressed: () => _saveRoute(route),
                      icon: const Icon(Icons.bookmark_border, size: 16),
                      label: const Text('收藏'),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => _startRoute(route),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('開始'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.blue[700])),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty) {
      case '初學者':
        color = Colors.green;
        break;
      case '中級':
        color = Colors.orange;
        break;
      case '進階':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(difficulty, style: const TextStyle(fontSize: 12)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return '今天';
    if (difference == 1) return '昨天';
    if (difference < 7) return '$difference 天前';
    return '${date.month}/${date.day}';
  }

  void _showRouteDetails(RouteData route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // 拖拽指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 路線名稱和評分
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text('${route.rating}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 基本資訊卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailInfo('距離', '${route.distance} km', Icons.straighten),
                          _buildDetailInfo('時間', '${route.estimatedDuration} 分', Icons.access_time),
                          _buildDetailInfo('爬升', '${route.elevation.toInt()} m', Icons.trending_up),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailInfo('難度', route.difficulty, Icons.fitness_center),
                          _buildDetailInfo('路面', route.surfaceType, Icons.texture),
                          _buildDetailInfo('類型', route.isLoop ? '環狀' : '單程', Icons.route),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 描述
              const Text('路線描述', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(route.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),

              // 起終點
              const Text('起終點資訊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('起點：${route.startPoint}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.stop, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('終點：${route.endPoint}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 路線亮點
              const Text('路線亮點', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: route.highlights.map((highlight) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(highlight, style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    )
                ).toList(),
              ),
              const SizedBox(height: 20),

              // 動作按鈕
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveRoute(route),
                      icon: const Icon(Icons.bookmark),
                      label: const Text('收藏路線'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startRoute(route),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('開始跑步'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _saveRoute(RouteData route) {
    // TODO: 實現儲存路線功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已收藏路線：${route.name}')),
    );
    print('儲存路線: ${route.name}');
  }

  void _startRoute(RouteData route) {
    // TODO: 實現開始跑步功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('開始跑步：${route.name}')),
    );
    print('開始跑步: ${route.name}');
  }
}