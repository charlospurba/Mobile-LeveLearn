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
  int? _localEquippedId;

  @override
  void initState() {
    super.initState();
    currentPoints = widget.user.points ?? 0;
    _localEquippedId = widget.user.equippedFrameId;

    _fetchUserTypeAndData();
    ActivityService.sendLog(userId: widget.user.id, type: 'EXPLORATION_EVENTS', value: 1.0);
  }

  String _getCleanAssetPath(String imgPath, String category) {
    if (imgPath.startsWith('lib/assets')) return imgPath;
    String cleanName = imgPath.split('.').first;
    
    if (category == "AVATAR") {
      return 'lib/assets/avatars/$cleanName.jpeg';
    } else {
      return 'lib/assets/Frames/$cleanName.png';
    }
  }

  Widget _buildImageWidget(String imgPath, String category, {double width = 80, double height = 80}) {
    if (imgPath.isEmpty) return const Icon(Icons.broken_image);
    bool isLocal = imgPath.contains('assets/') || !imgPath.contains('http');

    if (isLocal) {
      return Image.asset(
        _getCleanAssetPath(imgPath, category),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
      );
    } else {
      return Image.network(
        GlobalVar.formatImageUrl(imgPath),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
      );
    }
  }

  void _showSuccessAnimation(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _SuccessPopup(message: message),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _fetchUserTypeAndData() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final results = await Future.wait([
        http.get(Uri.parse("${GlobalVar.baseUrl}/api/user/adaptive/${widget.user.id}")).timeout(const Duration(seconds: 10)),
        UserService.getUserById(widget.user.id),
        TradeService.getAllTrades(),
        TradeService.getUserTrade(widget.user.id),
      ]);

      final profileResponse = results[0] as http.Response;
      final updatedUser = results[1] as Student;
      final allTrades = results[2] as List<TradeModel>;
      final ownedTrades = results[3] as List<UserTrade>;

      if (!mounted) return;

      setState(() {
        currentPoints = updatedUser.points ?? 0;
        _localEquippedId = updatedUser.equippedFrameId;

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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _equipFrameAction(int tradeId) async {
    final int? previousId = _localEquippedId;
    setState(() => _localEquippedId = tradeId);

    try {
      final response = await http.post(
        Uri.parse("${GlobalVar.baseUrl}/api/usertrade/equip"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.user.id, "tradeId": tradeId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessAnimation("Bingkai Berhasil Dipasang!");
        _fetchUserTypeAndData();
      } else {
        setState(() => _localEquippedId = previousId);
      }
    } catch (e) {
      setState(() => _localEquippedId = previousId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarItems = trades.where((t) => t.category == "AVATAR" || t.title.toLowerCase().contains('avatar')).toList();
    final shopFrames = trades.where((t) => t.category == "FRAME" || t.title.toLowerCase().contains('frame') || t.image.toLowerCase().contains('frame')).toList();
    final rewardTrades = trades.where((t) => t.category == "REWARD" && !t.title.toLowerCase().contains('avatar') && !t.title.toLowerCase().contains('frame')).toList();

    bool showRewards = userType != "Disruptors";
    bool showShop = (userType != "Achievers" && userType != "Free Spirits");
    int tabCount = 1 + (showRewards ? 1 : 0) + (showShop ? 1 : 0);

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
          actions: [_buildPointBadge()],
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
        body: SafeArea( // Tambahkan SafeArea agar tidak mepet ke navigasi bawah HP
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
              : TabBarView(
                  children: [
                    _buildAvatarGrid(avatarItems),
                    if (showRewards) _buildTradeList(rewardTrades, "Hadiah Belajar"),
                    if (showShop) _buildShopGrid(shopFrames),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPointBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text("$currentPoints", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // Perbaikan Grid Avatars agar tombol tidak mepet
  Widget _buildAvatarGrid(List<TradeModel> items) {
    if (items.isEmpty) return const Center(child: Text("Avatar tidak tersedia"));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Tambah padding bawah
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          childAspectRatio: 0.68, // DIUBAH: dikecilkan rasionya agar card lebih panjang ke bawah
          crossAxisSpacing: 12, 
          mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool canAfford = currentPoints >= item.priceInPoints;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Beri ruang di dalam card
            child: Column(
              children: [
                Expanded(
                  child: Center(child: _buildImageWidget(item.image, "AVATAR")),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => TradeDetailScreen(trade: item, user: widget.user, userType: userType)));
                        _fetchUserTypeAndData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.hasTrade ? Colors.green : (canAfford ? AppColors.primaryColor : Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        item.hasTrade ? "DIMILIKI" : "LIHAT DETAIL",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Perbaikan Grid Shop agar tombol tidak mepet
  Widget _buildShopGrid(List<TradeModel> frames) {
    if (frames.isEmpty) return const Center(child: Text("Bingkai tidak ditemukan"));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Tambah padding bawah
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          childAspectRatio: 0.60, // DIUBAH: dikecilkan agar card punya ruang untuk teks dan tombol
          crossAxisSpacing: 15, 
          mainAxisSpacing: 15),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final item = frames[index];
        bool canAfford = currentPoints >= item.priceInPoints;
        bool isEquipped = _localEquippedId == item.id;

        return Card(
          elevation: isEquipped ? 12 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isEquipped ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 65, height: 65,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
                        child: ClipOval(
                          child: widget.user.image != null
                              ? _buildImageWidget(widget.user.image!, "AVATAR")
                              : const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      ),
                      _buildImageWidget(item.image, "FRAME", width: 105, height: 105),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Text("${item.priceInPoints} Pts", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isEquipped ? null : () {
                            if (!item.hasTrade) {
                              if (canAfford) _processShopPurchase(item);
                            } else {
                              _equipFrameAction(item.id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped ? Colors.grey.shade400 : (item.hasTrade ? Colors.green : (canAfford ? AppColors.primaryColor : Colors.grey)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            !item.hasTrade ? "BELI" : (isEquipped ? "DIPAKAI" : "PASANG"),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradeList(List<TradeModel> list, String subtitle) {
    if (list.isEmpty) return const Center(child: Text("Belum ada data tersedia"));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trade = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.card_giftcard, color: Colors.white)),
            title: Text(trade.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: trade.hasTrade ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => TradeDetailScreen(trade: trade, user: widget.user, userType: userType)));
              _fetchUserTypeAndData();
            },
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
              content: Text("Gunakan ${item.priceInPoints} poin untuk mendapatkan ${item.title}?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      bool success = await TradeService.buyShopItem(widget.user.id, item.id, item.priceInPoints);
                      if (success) {
                        if (!mounted) return;
                        _showSuccessAnimation("Berhasil Ditukar!");
                        _fetchUserTypeAndData();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                    child: const Text("Tukar", style: TextStyle(color: Colors.white))),
              ],
            ));
  }
}

class _SuccessPopup extends StatefulWidget {
  final String message;
  const _SuccessPopup({required this.message});

  @override
  State<_SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<_SuccessPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _blinkAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: _blinkAnimation,
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 40, spreadRadius: 15)],
                      ),
                    ),
                  ),
                  const Icon(Icons.stars, color: Colors.amber, size: 100),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Text(widget.message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}