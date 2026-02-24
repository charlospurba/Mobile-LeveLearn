import 'package:app/model/trade.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/user_badge_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/view/whatadeal_screen.dart';
import 'package:app/global_var.dart';
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
  late Student user;

  // --- LOGIKA KATEGORI ---
  // Avatar sekarang resmi hanya menggunakan Point (Shop Item)
  bool get isAvatar => widget.trade.category == "AVATAR" || widget.trade.title.toLowerCase().contains('avatar');
  
  bool get isFrame => widget.trade.category == "FRAME" || widget.trade.image.toLowerCase().contains('frame');
  
  // Item kategori Shop (Avatar & Frame) tidak butuh Badge
  bool get isShopItem => isAvatar || isFrame;

  @override
  void initState() {
    user = widget.user;
    _initData();
    super.initState();
  }

  Future<void> _initData() async {
    pref = await SharedPreferences.getInstance();
    // Hanya fetch badge jika item yang dipilih adalah REWARD (bukan avatar/frame)
    if (!isShopItem) {
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
      debugPrint("Error Fetching Badges: $e");
    }
  }

  int _calculateReqPoint() {
    // Sinkronisasi dengan price list di UserController.js
    if (isAvatar) {
      final Map<int, int> prices = { 
        1: 0, 2: 100, 3: 100, 4: 100, 5: 200, 6: 200, 
        7: 250, 8: 250, 9: 300, 10: 300, 11: 350, 12: 350 
      };
      return prices[widget.trade.id] ?? (widget.trade.priceInPoints > 0 ? widget.trade.priceInPoints : 500);
    }
    
    if (isFrame) {
      return widget.trade.priceInPoints > 0 ? widget.trade.priceInPoints : 2500;
    }

    // Untuk REWARD yang butuh lencana
   String type = widget.trade.requiredBadgeType?.toUpperCase() ?? "";
    switch (type) {
      case 'BEGINNER': return 2000;
      case 'INTERMEDIATE': return 4000;
      case 'ADVANCE': return 6000;
      default: return widget.trade.priceInPoints;
    }
  }

  bool _isPurchaseValid() {
    int reqPoint = _calculateReqPoint();
    if ((user.points ?? 0) < reqPoint) return false;
    
    // Jika Avatar atau Frame, validasi berhenti di poin saja
    if (isShopItem) return true; 
    
    // Jika Reward, wajib pilih salah satu lencana yang dimiliki
    return selectedBadgeToTrade != null;
  }

  Future<void> _processRedeem() async {
    int reqPoint = _calculateReqPoint();
    
    // Loading dialog
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
    );

    try {
      bool success = false;

      if (isShopItem) {
        // Transaksi HANYA POIN untuk Avatar & Frame
        success = await TradeService.buyShopItem(user.id, widget.trade.id, reqPoint);
      } else {
        // Transaksi REWARD (Poin + Badge)
        success = await TradeService.createUserTrade(user.id, widget.trade.id);
      }
      
      if (success) {
        // Update local user points
        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);

        // Jika ini reward, tandai badge sebagai "sudah digunakan/purchased"
        if (!isShopItem && selectedBadgeToTrade != null) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadgeToTrade!.id, true);
        }

        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        
        // Pindah ke screen sukses
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (c) => WhatADealScreen(message: "Selamat! ${widget.trade.title} berhasil didapatkan."))
        );
      } else {
        throw Exception("Gagal memproses transaksi di server.");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi Kesalahan: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int reqPoint = _calculateReqPoint();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAvatar ? "Beli Avatar" : (isFrame ? "Beli Bingkai" : "Tukar Reward")),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  Text(
                    widget.trade.title, 
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.trade.description, 
                    style: const TextStyle(color: Colors.grey, fontSize: 16)
                  ),
                  const SizedBox(height: 30),
                  
                  // Card Persyaratan
                  _buildRequirementCard(reqPoint),
                  
                  // Picker Badge (Hanya muncul jika kategori REWARD)
                  if (!isShopItem) ...[
                    const SizedBox(height: 25),
                    const Text("Pilih Lencana untuk Ditukar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.stars, color: hasEnoughPoints ? Colors.amber : Colors.red, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Biaya: $reqPoint Poin", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Poin Anda: ${user.points}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
          ]),
          if (!isShopItem) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(),
            ),
            Row(children: [
              Icon(Icons.verified_user, color: userOwnedBadges.isNotEmpty ? Colors.blue : Colors.red, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "Membutuhkan 1x Lencana ${widget.trade.requiredBadgeType}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ]),
          ]
        ],
      ),
    );
  }

  Widget _buildTradeImage() {
    String path = widget.trade.image;
    bool isLocalAsset = !path.contains('http');

    return Container(
      height: 280, 
      width: double.infinity, 
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))
      ),
      padding: const EdgeInsets.all(40),
      child: Hero(
        tag: 'trade-${widget.trade.id}',
        child: isLocalAsset 
          ? Image.asset(
              _formatAssetPath(path),
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            )
          : Image.network(
              GlobalVar.formatImageUrl(path), 
              fit: BoxFit.contain, 
              errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
            ),
      ),
    );
  }

  String _formatAssetPath(String imgName) {
    if (imgName.startsWith('lib/assets')) return imgName;
    String cleanName = imgName.split('.').first;
    
    if (isAvatar) {
      return 'lib/assets/avatars/$cleanName.jpeg';
    } else {
      return 'lib/assets/Frames/$cleanName.png';
    }
  }

  Widget _buildBadgePicker() {
    if (userOwnedBadges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red),
            SizedBox(width: 10),
            Expanded(child: Text("Anda belum memiliki lencana yang diperlukan untuk menukar reward ini.", style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: userOwnedBadges.map((ub) {
        bool isSelected = selectedBadgeToTrade == ub;
        return ChoiceChip(
          label: Text(ub.badge?.name ?? "Lencana"),
          selected: isSelected,
          selectedColor: AppColors.primaryColor.withOpacity(0.3),
          onSelected: (val) => setState(() => selectedBadgeToTrade = val ? ub : null),
        );
      }).toList(),
    );
  }

  Widget _buildRedeemButton() {
    bool alreadyOwned = widget.trade.hasTrade;
    bool canRedeem = !alreadyOwned && _isPurchaseValid();
    
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor, 
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0
        ),
        onPressed: canRedeem ? _processRedeem : null,
        child: Text(
          alreadyOwned 
            ? "SUDAH DIMILIKI" 
            : (isShopItem ? "BELI SEKARANG" : "TUKAR REWARD"), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
    );
  }
}