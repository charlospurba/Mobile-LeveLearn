import 'package:app/model/trade.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/user_badge_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/service/activity_service.dart';
import 'package:app/view/whatadeal_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../utils/colors.dart';

class TradeDetailScreen extends StatefulWidget {
  final TradeModel trade;
  final Student user;
  final String userType;

  const TradeDetailScreen({
    super.key, 
    required this.trade, 
    required this.user, 
    required this.userType
  });

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  late SharedPreferences pref;
  List<UserBadge> userOwnedBadges = [];
  UserBadge? selectedBadgeToTrade;
  String errorMessage = '';
  late Student user;

  // DETEKSI KATEGORI BERDASARKAN BACKEND
  // Avatar dideteksi dari category "AVATAR" atau title yang mengandung kata avatar
  bool get isAvatar => widget.trade.category == "AVATAR" || widget.trade.title.toLowerCase().contains("avatar");
  
  // Shop item adalah item yang TIDAK butuh badge (requiredBadgeType null)
  bool get isShopItem => widget.trade.requiredBadgeType == null || widget.trade.requiredBadgeType!.isEmpty;

  @override
  void initState() {
    user = widget.user;
    _initData();
    super.initState();
  }

  Future<void> _initData() async {
    pref = await SharedPreferences.getInstance();
    // Jika BUKAN avatar dan BUKAN shop item, baru cari badge (berarti ini Reward murni)
    if (!isAvatar && !isShopItem) {
      _fetchAvailableBadgesForTrade();
    }
  }

  Future<void> _fetchAvailableBadgesForTrade() async {
    try {
      final result = await BadgeService.getUserBadgeListByUserId(user.id);
      if (mounted) {
        setState(() {
          userOwnedBadges = result.where((b) {
            final badgeModel = b.badge;
            if (badgeModel == null || widget.trade.requiredBadgeType == null) return false;
            
            return !b.isPurchased && 
                   badgeModel.type.toUpperCase() == widget.trade.requiredBadgeType!.toUpperCase();
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Badges: $e");
    }
  }

  int _calculateReqPoint() {
    // SINKRONISASI DENGAN BACKEND purchaseAvatar prices
    if (isAvatar) {
      int avatarId = widget.trade.id;
      // Map harga sesuai controller backend: { 1:0, 2:100, 3:100, 4:100, 5:200, ... }
      final Map<int, int> prices = { 1: 0, 2: 100, 3: 100, 4: 100, 5: 200, 6: 200, 7: 250, 8: 250, 9: 300, 10: 300, 11: 350, 12: 350 };
      return prices[avatarId] ?? 999;
    }

    // Jika ada harga poin di DB (untuk Frame/Shop), pakai itu
    if (widget.trade.priceInPoints > 0) {
      return widget.trade.priceInPoints;
    }

    // Untuk Reward (Berdasarkan Tipe Badge)
    String type = widget.trade.requiredBadgeType?.toUpperCase() ?? "";
    switch (type) {
      case 'BEGINNER': return 300;
      case 'INTERMEDIATE': return 500;
      case 'ADVANCE': return 800;
      default: return 0;
    }
  }

  bool _isPurchaseValid() {
    int reqPoint = _calculateReqPoint();
    if ((user.points ?? 0) < reqPoint) return false;
    
    // Avatar tidak butuh badge
    if (isAvatar) return true;

    // Hanya item Reward non-shop yang wajib pilih badge
    if (!isShopItem) {
      if (selectedBadgeToTrade == null) return false;
    }
    return true;
  }

  Future<void> _processRedeem() async {
    int reqPoint = _calculateReqPoint();
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      bool success = false;

      // Panggil service sesuai jenis item
      if (isAvatar || isShopItem) {
        // Pembelian menggunakan poin
        success = await TradeService.buyShopItem(user.id, widget.trade.id, reqPoint);
      } else {
        // Penukaran reward (butuh badge)
        success = await TradeService.createUserTrade(user.id, widget.trade.id);
      }
      
      if (success) {
        // Update poin di lokal
        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);

        // Jika pakai badge, tandai badge tersebut sudah terpakai
        if (!isAvatar && !isShopItem && selectedBadgeToTrade != null) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadgeToTrade!.id, true);
        }

        if (!mounted) return;
        Navigator.pop(context); 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => WhatADealScreen(message: "Sukses! ${widget.trade.title} didapatkan.")));
      } else {
        throw Exception("Gagal memproses transaksi");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int reqPoint = _calculateReqPoint();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAvatar ? "Beli Avatar" : "Tukar Reward"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTradeImage(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.trade.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.trade.description, style: const TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 30),
                  _buildRequirementCard(reqPoint),

                  // Tampilkan pemilih badge HANYA jika bukan Avatar dan bukan Shop Item
                  if (!isAvatar && !isShopItem) ...[
                    const SizedBox(height: 25),
                    const Text("Pilih Badge Koleksi Anda:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildBadgePicker(),
                  ],

                  const SizedBox(height: 40),
                  _buildRedeemButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementCard(int reqPoint) {
    bool hasEnoughPoints = (user.points ?? 0) >= reqPoint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.monetization_on, color: hasEnoughPoints ? Colors.green : Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text("Biaya: $reqPoint Poin (Miliki: ${user.points})")),
          ]),
          // Syarat Badge disembunyikan jika ini adalah Avatar
          if (!isAvatar && !isShopItem) ...[
            const Divider(height: 24),
            Row(children: [
              Icon(Icons.verified, color: userOwnedBadges.isNotEmpty ? Colors.green : Colors.red),
              const SizedBox(width: 10),
              Expanded(child: Text("Butuh 1x Badge ${widget.trade.requiredBadgeType}")),
            ]),
          ]
        ],
      ),
    );
  }

  // Sisa fungsi UI (_buildBadgePicker, _buildRedeemButton, _buildTradeImage) tetap sama
  // Namun _buildRedeemButton sekarang otomatis valid untuk Avatar jika poin cukup.

  Widget _buildBadgePicker() {
    if (userOwnedBadges.isEmpty) {
      return const Text("Lencana tidak mencukupi.", style: TextStyle(color: Colors.red, fontSize: 13));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: userOwnedBadges.map((ub) {
        final badgeName = ub.badge?.name ?? "Badge"; 
        return ChoiceChip(
          label: Text(badgeName),
          selected: selectedBadgeToTrade == ub,
          onSelected: (val) => setState(() => selectedBadgeToTrade = val ? ub : null),
        );
      }).toList(),
    );
  }

  Widget _buildRedeemButton() {
    bool canRedeem = !widget.trade.hasTrade && _isPurchaseValid();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor, 
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        onPressed: canRedeem ? _processRedeem : null,
        child: Text(
          widget.trade.hasTrade ? "TELAH DIMILIKI" : (isAvatar ? "BELI SEKARANG" : "TUKAR SEKARANG"), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _buildTradeImage() {
    return Container(
      height: 200, width: double.infinity, color: Colors.grey.shade100,
      child: Image.network(widget.trade.image, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.face, size: 100)),
    );
  }
}