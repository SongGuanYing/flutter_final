import 'package:flutter/material.dart';
import 'record.dart';
import 'main.dart';

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
  final String gpxPath; // 添加這個屬性

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
    this.gpxPath = 'assets/gpx/route1.gpx', // 設置默認GPX路徑
  });
}

// 索引 4: 路線 - 路線推薦與詳細資料
class RoutePage extends StatefulWidget {
  final Function(RouteData) onStartRoute; // 宣告一個函式類型的參數

  const RoutePage({
    Key? key,
    required this.onStartRoute, // 設為必要參數
  }) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  String? _selectedDifficulty;
  String? _selectedType;
  final List<String> _difficultyOptions = ['初學者', '中級', '進階'];
  final List<String> _typeOptions = ['環狀', '單程'];

  // 模擬推薦路線數據 - 增加更多路線選擇
  final List<RouteData> mockRoutes = [
    RouteData(
      id: '1',
      name: '蘭潭學餐環線',
      distance: 0.5,
      estimatedDuration: 5,
      difficulty: '初學者',
      elevation: 5.0,
      tags: ['校園', '安全', '夜跑'],
      rating: 4.1,
      reviewCount: 96,
      description: '大學校園內的慢跑路線，路燈充足，安全性高，適合晚上跑步。路面平坦，適合初學者建立跑步習慣。',
      startPoint: '校門口',
      endPoint: '校門口',
      highlights: ['路燈充足', '安全環境', '便利商店', '停車方便'],
      surfaceType: '柏油路面',
      isLoop: true,
      gpxPath: 'assets/gpx/route2.gpx',
    ),
    RouteData(
      id: '2',
      name: '蘭潭後山環線',
      distance: 3.8,
      estimatedDuration: 103,
      difficulty: '中級',
      elevation: 64.1,
      tags: ['潭景', '自然', '微坡'],
      rating: 4.2,
      reviewCount: 87,
      description: '沿著河濱的自行車道，有輕微坡度變化，適合中級跑者。途中可欣賞河景和城市天際線。',
      startPoint: '步道入口',
      endPoint: '步道入口',
      highlights: ['潭景', '涼亭休息點', '野鳥觀察', '廁所'],
      surfaceType: '混合路面',
      isLoop: false,
      gpxPath: 'assets/gpx/route1.gpx',
    ),
    RouteData(
      id: '3',
      name: '嘉義公園散步',
      distance: 2.0,
      estimatedDuration: 27,
      difficulty: '初學者',
      elevation: 28.0,
      tags: ['公園', '芬多精', '平坦'],
      rating: 4.5,
      reviewCount: 128,
      description: '這條路線遍歷嘉義公園內的步道。',
      startPoint: '公園北側',
      endPoint: '公園南側',
      highlights: ['棒球場', '涼亭休息點', '芬多精', '廁所'],
      surfaceType: '石板步道',
      isLoop: true,
      gpxPath: 'assets/gpx/route3.gpx',
    ),
    RouteData(
      id: '4',
      name: '阿里山眠月線挑戰',
      distance: 14.82,
      estimatedDuration: 306,
      difficulty: '進階',
      elevation: 545.95,
      tags: ['山丘', '挑戰', '陡坡'],
      rating: 4.7,
      reviewCount: 45,
      description: '具有挑戰性的山丘路線，適合進階跑者。雖然辛苦但風景絕佳，是訓練體能的好選擇。',
      startPoint: '阿里山閣大飯店',
      endPoint: '阿里山閣大飯店',
      highlights: ['山林美景', '鐵道遺蹟', '森林浴', '挑戰坡度'],
      surfaceType: '混合步道',
      isLoop: false,
      gpxPath: 'assets/gpx/route4.gpx',
    ),
    RouteData(
      id: '5',
      name: '城市步道探索線',
      distance: 2.82,
      estimatedDuration: 46,
      difficulty: '中級',
      elevation: 13.71,
      tags: ['城市', '步道', '景觀'],
      rating: 4.4,
      reviewCount: 73,
      description: '穿越城市各個特色區域的步道路線，有小幅度爬升，可以欣賞不同的城市風貌和建築特色。',
      startPoint: '中央車站',
      endPoint: '藝術園區',
      highlights: ['城市景觀', '建築特色', '咖啡廳', '文化景點'],
      surfaceType: '人行步道',
      isLoop: false,
      gpxPath: 'assets/gpx/route5.gpx',
    ),
    RouteData(
      id: '6',
      name: '海岸線晨跑路線',
      distance: 71.69,
      estimatedDuration: 438,
      difficulty: '中級',
      elevation: 6.11,
      tags: ['海岸', '晨跑', '海風'],
      rating: 4.8,
      reviewCount: 156,
      description: '沿著美麗海岸線的晨跑路線，可以享受清新海風和日出美景。略有起伏但不會太累，是很受歡迎的路線。',
      startPoint: '海濱公園',
      endPoint: '漁港',
      highlights: ['海景', '日出', '海風', '漁港風情'],
      surfaceType: '木棧道',
      isLoop: false,
      gpxPath: 'assets/gpx/route6.gpx',
    ),
    RouteData(
      id: '7',
      name: '半天岩-烏心石山',
      distance: 7.01,
      estimatedDuration: 195,
      difficulty: '中級',
      elevation: 443.32,
      tags: ['森林', '自然', '芬多精'],
      rating: 4.6,
      reviewCount: 67,
      description: '森林公園內的環狀步道，在樹林間跑步可以享受芬多精和自然美景。有適度坡度變化，適合中級跑者。',
      startPoint: '森林公園入口',
      endPoint: '森林公園入口',
      highlights: ['森林浴', '芬多精', '野生動物', '涼爽環境'],
      surfaceType: '石板步道',
      isLoop: true,
      gpxPath: 'assets/gpx/route7.gpx',
    ),
    RouteData(
      id: '8',
      name: '北香湖公園',
      distance: 3.91,
      estimatedDuration: 79,
      difficulty: '初學者',
      elevation: 10.77,
      tags: ['運動公園', '設施完善', '平坦'],
      rating: 4.3,
      reviewCount: 112,
      description: '運動公園內的大環線，設施完善，有飲水機、廁所和休息區。地勢平坦，非常適合初學者和家庭跑步。',
      startPoint: '停車場',
      endPoint: '停車場',
      highlights: ['運動設施', '飲水機', '廁所', '燈光造景'],
      surfaceType: '混和路面',
      isLoop: true,
      gpxPath: 'assets/gpx/route8.gpx',
    ),
    RouteData(
      id: '9',
      name: '古蹟文化路線',
      distance: 5.8,
      estimatedDuration: 58,
      difficulty: '中級',
      elevation: 40.0,
      tags: ['古蹟', '文化', '歷史'],
      rating: 4.2,
      reviewCount: 89,
      description: '經過多個古蹟和文化景點的路線，在跑步的同時可以欣賞歷史建築和文化遺產。有小幅爬升但不會太困難。',
      startPoint: '古城門',
      endPoint: '文化館',
      highlights: ['古蹟建築', '文化景點', '歷史解說', '拍照景點'],
      surfaceType: '石磚路面',
      isLoop: false,
      gpxPath: 'assets/gpx/route1.gpx',
    ),
    RouteData(
      id: '10',
      name: '極限山徑挑戰',
      distance: 8.5,
      estimatedDuration: 95,
      difficulty: '進階',
      elevation: 200.0,
      tags: ['山徑', '極限', '挑戰'],
      rating: 4.9,
      reviewCount: 34,
      description: '高難度的山徑路線，適合有經驗的跑者挑戰。路線包含陡峭爬升和技術性路段，但山頂景色絕對值得。',
      startPoint: '登山口停車場',
      endPoint: '山頂觀景台',
      highlights: ['絕佳山景', '挑戰性路段', '成就感', '野生動植物'],
      surfaceType: '山徑小路',
      isLoop: false,
      gpxPath: 'assets/gpx/route1.gpx',
    ),
    RouteData(
      id: '11',
      name: '夜市美食環線',
      distance: 3.5,
      estimatedDuration: 35,
      difficulty: '初學者',
      elevation: 8.0,
      tags: ['夜市', '美食', '熱鬧'],
      rating: 4.0,
      reviewCount: 145,
      description: '繞行熱鬧夜市周邊的路線，跑完可以直接享受美食！路線平坦好跑，適合想要跑步後享受美食的跑者。',
      startPoint: '夜市入口',
      endPoint: '夜市入口',
      highlights: ['夜市美食', '熱鬧氣氛', '路燈充足', '交通便利'],
      surfaceType: '柏油路面',
      isLoop: true,
      gpxPath: 'assets/gpx/route1.gpx',
    ),
    RouteData(
      id: '12',
      name: '嘉油鐵馬道、糖鐵自行車道',
      distance: 31.41,
      estimatedDuration: 694,
      difficulty: '進階',
      elevation: 228.70,
      tags: ['長距離', '鐵馬道', '耐力'],
      rating: 4.5,
      reviewCount: 28,
      description: '長距離的鐵馬道路線，適合進階跑者進行耐力訓練。沿途風景多變，是挑戰個人極限的好選擇。',
      startPoint: '鐵馬道起點',
      endPoint: '新營車站',
      highlights: ['長距離挑戰', '多變風景', '耐力訓練', '休息補給站'],
      surfaceType: '混和路面',
      isLoop: false,
      gpxPath: 'assets/gpx/route12.gpx',
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
      gpxPath: 'assets/gpx/route1.gpx',
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
      gpxPath: 'assets/gpx/route1.gpx',
    ),
  ];

  List<RouteData> get filteredRoutes {
    List<RouteData> filtered = mockRoutes;

    // 根據難度篩選
    if (_selectedDifficulty != null) {
      filtered =
          filtered.where((r) => r.difficulty == _selectedDifficulty).toList();
    }

    // 根據類型篩選
    if (_selectedType != null) {
      bool isLoop = _selectedType == '環狀';
      filtered = filtered.where((r) => r.isLoop == isLoop).toList();
    }

    return filtered;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('篩選路線',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDifficulty = null;
                      _selectedType = null;
                    });
                  },
                  child: const Text('清除篩選'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 難度篩選
            const Text('難度等級',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _difficultyOptions
                  .map((difficulty) => ChoiceChip(
                        label: Text(difficulty),
                        selected: _selectedDifficulty == difficulty,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDifficulty = selected ? difficulty : null;
                          });
                        },
                        selectedColor:
                            _getDifficultyColor(difficulty).withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: _selectedDifficulty == difficulty
                              ? _getDifficultyColor(difficulty)
                              : null,
                          fontWeight: _selectedDifficulty == difficulty
                              ? FontWeight.bold
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // 路線類型篩選
            const Text('路線類型',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _typeOptions
                  .map((type) => ChoiceChip(
                        label: Text(type),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: _selectedType == type
                              ? Theme.of(context).primaryColor
                              : null,
                          fontWeight:
                              _selectedType == type ? FontWeight.bold : null,
                        ),
                      ))
                  .toList(),
            ),

            // 顯示當前篩選結果
            if (_selectedDifficulty != null || _selectedType != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '篩選結果：${filteredRoutes.length} 條路線',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '初學者':
        return Colors.green;
      case '中級':
        return Colors.orange;
      case '進階':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                const Text('推薦路線',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            ...filteredRoutes
                .map((route) => _buildRouteCard(route, false))
                .toList(),
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
                    foregroundColor: Colors.white),
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
                const Text('已儲存路線',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            ...mockSavedRoutes
                .map((route) => _buildRouteCard(route, true))
                .toList(),
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                  _buildInfoChip(
                      Icons.access_time, '${route.estimatedDuration} 分鐘'),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                      Icons.trending_up, '${route.elevation.toInt()}m'),
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
                children: route.tags
                    .take(3)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Text(tag, style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
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
    Color color = _getDifficultyColor(difficulty);

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
      backgroundColor: Colors.transparent,
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
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
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
                          _buildDetailInfo(
                              '距離', '${route.distance} km', Icons.straighten),
                          _buildDetailInfo('時間', '${route.estimatedDuration} 分',
                              Icons.access_time),
                          _buildDetailInfo('爬升', '${route.elevation.toInt()} m',
                              Icons.trending_up),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailInfo(
                              '難度', route.difficulty, Icons.fitness_center),
                          _buildDetailInfo(
                              '路面', route.surfaceType, Icons.texture),
                          _buildDetailInfo(
                              '類型', route.isLoop ? '環狀' : '單程', Icons.route),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 描述
              const Text('路線描述',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(route.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),

              // 起終點
              const Text('起終點資訊',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const Text('路線亮點',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: route.highlights
                    .map((highlight) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_outline,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(highlight,
                                  style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ))
                    .toList(),
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
                      onPressed: () => setState(() {
                        _startRoute(route);
                        Navigator.pop(context);
                      }),
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
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

  // 修改 _startRoute 方法，使用 Navigator.push 並傳遞路線參數
  void _startRoute(RouteData route) {
    // 直接呼叫從父層 (HomeScreen) 傳進來的函式，並把路線資料傳回去
    widget.onStartRoute(route);

    print('觸發開始跑步: ${route.name}, GPX路徑: ${route.gpxPath}');
  }
}
