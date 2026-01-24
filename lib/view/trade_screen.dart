import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/activity_service.dart'; // IMPORT BARU
import 'package:app/utils/colors.dart';
import 'package:app/view/main_screen.dart';
import 'package:app/view/trade_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    
    // LOG TRIGGER: FREE SPIRITS (Exploration Events)
    // Mencatat bahwa user tertarik menjelajahi fitur di luar materi kursus
    ActivityService.sendLog(
      userId: widget.user.id, 
      type: 'EXPLORATION_EVENTS', 
      value: 1.0
    );
    
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final allTrades = await TradeService.getAllTrades();
      final ownedTrades = await TradeService.getUserTrade(widget.user.id);
      
      if (!mounted) return;

      setState(() {
        trades = allTrades;
        userTrade = ownedTrades;
        
        final tradeIds = userTrade.map((t) => t.tradeId).toSet();
        for (var t in trades) {
          t.hasTrade = tradeIds.contains(t.id);
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarTrades = trades.where((t) => t.title.toLowerCase().contains('avatar')).toList();
    final rewardTrades = trades.where((t) => !t.title.toLowerCase().contains('avatar')).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trade Center"),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Mainscreen(navIndex: 4))),
            icon: const Icon(LineAwesomeIcons.angle_left_solid),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.face), text: "Avatars"),
              Tab(icon: Icon(Icons.card_giftcard), text: "Rewards"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover),
          ),
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTradeList(avatarTrades, true),
                  _buildTradeList(rewardTrades, false),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildTradeList(List<TradeModel> list, bool isAvatar) {
    if (list.isEmpty) {
      return const Center(child: Text("Belum ada penawaran tersedia", style: TextStyle(fontFamily: 'DIN_Next_Rounded')));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trade = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(trade.image, width: 60, height: 60, fit: BoxFit.cover, 
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60)),
            ),
            title: Text(trade.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
            subtitle: Text(
              isAvatar ? "Tukarkan poin untuk koleksi ini" : "Butuh badge: ${trade.requiredBadgeType}",
              style: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
            ),
            trailing: trade.hasTrade 
              ? const Icon(Icons.check_circle, color: Colors.green) 
              : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => TradeDetailScreen(trade: trade, user: widget.user)));
              fetchData(); 
            },
          ),
        );
      },
    );
  }
}