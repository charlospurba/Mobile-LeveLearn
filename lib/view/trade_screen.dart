import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/activity_service.dart';
import 'package:app/service/user_service.dart'; 
import 'package:app/utils/colors.dart';
import 'package:app/global_var.dart';
import 'package:app/view/main_screen.dart';
import 'package:app/view/trade_detail_screen.dart';
import 'package:app/view/avatar_frame_painter.dart'; 
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../model/user.dart';

class TradeScreen extends StatefulWidget {
  final Student user;
  const TradeScreen({super.key, required this.user});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  List<TradeModel> trades = [];
  List<UserTrade> userTrade = [];
  bool isLoading = true;
  String userType = "Players"; 
  int currentPoints = 0; 
  final String serverIp = "10.106.207.43"; 

  @override
  void initState() {
    super.initState();
    currentPoints = widget.user.points ?? 0;
    _fetchUserTypeAndData();
    ActivityService.sendLog(userId: widget.user.id, type: 'EXPLORATION_EVENTS', value: 1.0);
  }

  String formatUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('lib/assets/')) return url;
    if (url.contains('localhost')) return url.replaceAll('localhost', serverIp);
    if (!url.startsWith('http')) return 'http://$serverIp:7000$url';
    return url;
  }

  Future<void> _fetchUserTypeAndData() async {
    try {
      final String url = "http://10.106.207.43:7000/api/user/adaptive/${widget.user.id}";
      final profileResponse = await http.get(Uri.parse(url));
      
      final Student updatedUser = await UserService.getUserById(widget.user.id);
      final allTrades = await TradeService.getAllTrades();
      final ownedTrades = await TradeService.getUserTrade(widget.user.id);
      
      if (!mounted) return;

      setState(() {
        currentPoints = updatedUser.points ?? 0;
        
        if (profileResponse.statusCode == 200) {
          final data = jsonDecode(profileResponse.body);
          userType = data['currentCluster'] ?? "Players";
        }

        trades = allTrades;
        userTrade = ownedTrades;
        
        final tradeIds = userTrade.map((t) => t.tradeId).toSet();
        for (var t in trades) {
          t.hasTrade = tradeIds.contains(t.id);
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _equipFrameAction(int tradeId) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.106.207.43:7000/api/usertrade/equip"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.user.id, "tradeId": tradeId}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bingkai berhasil dipasang!")));
        _fetchUserTypeAndData(); 
      }
    } catch (e) {
      debugPrint("Error equip action: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarItems = trades.where((t) => t.category == "AVATAR" || t.title.toLowerCase().contains('avatar')).toList();
    final rewardTrades = trades.where((t) => t.category == "REWARD" && !t.title.toLowerCase().contains('avatar')).toList();
    final shopFrames = trades.where((t) => t.category == "FRAME").toList();

    bool showRewards = userType != "Disruptors";
    bool showShop = (userType != "Achievers" && userType != "Free Spirits"); 
    
    int tabCount = 1; 
    if (showRewards) tabCount++;
    if (showShop) tabCount++;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trade Center", style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainscreen(navIndex: 4))),
            icon: const Icon(LineAwesomeIcons.angle_left_solid),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [
              const Tab(icon: Icon(Icons.face), text: "Avatars"),
              if (showRewards) const Tab(icon: Icon(Icons.card_giftcard), text: "Rewards"),
              if (showShop) const Tab(icon: Icon(Icons.shopping_cart), text: "Shop"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover, opacity: 0.1),
          ),
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAvatarGrid(avatarItems), 
                  if (showRewards) _buildTradeList(rewardTrades, "Hadiah dari Badge Anda"),
                  if (showShop) _buildShopGrid(shopFrames), 
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAvatarGrid(List<TradeModel> items) {
    if (items.isEmpty) return const Center(child: Text("Belum ada avatar tersedia"));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String imgPath = item.image;
        bool isLocal = imgPath.startsWith('lib/assets/');

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: imgPath.isNotEmpty && !imgPath.startsWith("DESIGN_")
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isLocal
                          ? Image.asset(imgPath, width: 70, height: 70, fit: BoxFit.cover)
                          : Image.network(
                              formatUrl(imgPath), 
                              width: 70, height: 70, fit: BoxFit.cover, 
                              errorBuilder: (c,e,s) => const Icon(Icons.face, size: 50)
                            ),
                      )
                    : const Icon(Icons.face, size: 50),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => TradeDetailScreen(trade: item, user: widget.user, userType: userType)));
                          _fetchUserTypeAndData();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                        child: const Text("Tukar", style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeList(List<TradeModel> list, String subtitleText) {
    if (list.isEmpty) return const Center(child: Text("Belum ada data tersedia"));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trade = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.blue),
            title: Text(trade.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitleText, style: const TextStyle(fontSize: 12)),
            trailing: trade.hasTrade ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(LineAwesomeIcons.angle_right_solid),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => TradeDetailScreen(trade: trade, user: widget.user, userType: userType)));
              _fetchUserTypeAndData(); 
            },
          ),
        );
      },
    );
  }

  Widget _buildShopGrid(List<TradeModel> frames) {
    if (frames.isEmpty) return const Center(child: Text("Bingkai tidak ditemukan"));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final item = frames[index];
        bool canAfford = currentPoints >= item.priceInPoints;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 80, height: 80,
                    child: CustomPaint(painter: AvatarFramePainter(item.image.isNotEmpty ? item.image : "null")),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                    Text("${item.priceInPoints} Pts", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: item.hasTrade 
                            ? () => _equipFrameAction(item.id) 
                            : (canAfford ? () => _processShopPurchase(item) : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.hasTrade ? Colors.green : AppColors.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        child: Text(
                          item.hasTrade ? "Gunakan" : (canAfford ? "Beli" : "Poin Kurang"), 
                          style: const TextStyle(color: Colors.white, fontSize: 11)
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _processShopPurchase(TradeModel item) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text("Beli ${item.title} seharga ${item.priceInPoints} poin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await TradeService.buyShopItem(widget.user.id, item.id, item.priceInPoints);
              if (success) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil membeli ${item.title}!")));
                await _fetchUserTypeAndData(); 
              }
            }, 
            child: const Text("Ya, Beli")
          ),
        ],
      )
    );
  }
}