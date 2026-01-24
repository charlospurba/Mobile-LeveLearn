import 'package:app/model/trade.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/user_badge_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/service/activity_service.dart'; // IMPORT BARU
import 'package:app/view/whatadeal_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../utils/colors.dart';

class TradeDetailScreen extends StatefulWidget {
  final TradeModel trade;
  final Student user;

  const TradeDetailScreen({super.key, required this.trade, required this.user});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  late SharedPreferences pref;
  List<UserBadge> userOwnedBadges = [];
  UserBadge? selectedBadgeToTrade;
  String errorMessage = '';
  late Student user;

  bool get isAvatar => widget.trade.title.toLowerCase().contains("avatar");

  @override
  void initState() {
    user = widget.user;
    _initData();
    super.initState();
  }

  Future<void> _initData() async {
    pref = await SharedPreferences.getInstance();
    if (!isAvatar) {
      _fetchAvailableBadgesForTrade();
    }
  }

  Future<void> _fetchAvailableBadgesForTrade() async {
    try {
      final result = await BadgeService.getUserBadgeListByUserId(user.id);
      setState(() {
        userOwnedBadges = result.where((b) => 
          !b.isPurchased && 
          b.badge!.type.toUpperCase() == widget.trade.requiredBadgeType.toUpperCase()
        ).toList();
      });
    } catch (e) {
      debugPrint("Error Fetching Badges: $e");
    }
  }

  int _calculateReqPoint() {
    if (isAvatar) {
      int id = widget.trade.id;
      if (id <= 1) return 0;
      if (id <= 4) return 100;
      if (id <= 6) return 200;
      if (id <= 8) return 250;
      if (id <= 10) return 300;
      return 350;
    } else {
      switch (widget.trade.requiredBadgeType.toUpperCase()) {
        case 'BEGINNER': return 300;
        case 'INTERMEDIATE': return 500;
        case 'ADVANCE': return 800;
        default: return 0;
      }
    }
  }

  bool _isPurchaseValid() {
    int reqPoint = _calculateReqPoint();
    if ((user.points ?? 0) < reqPoint) return false;
    if (!isAvatar) {
      if (selectedBadgeToTrade == null) return false;
    }
    return true;
  }

  Future<void> _processRedeem() async {
    int reqPoint = _calculateReqPoint();
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    try {
      bool success = await TradeService.createUserTrade(user.id, widget.trade.id);
      
      if (success) {
        // LOG TRIGGER: PLAYERS (Reward Behavior Proxy)
        // User telah menukar poin/badge untuk mendapatkan item gamifikasi
        ActivityService.sendLog(
          userId: user.id, 
          type: 'REWARD_BEHAVIOR_PROXY', 
          value: 1.0,
          metadata: {"item_title": widget.trade.title, "cost": reqPoint}
        );

        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);

        if (!isAvatar && selectedBadgeToTrade != null) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadgeToTrade!.id, true);
        }

        if (!mounted) return;
        Navigator.pop(context); 
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (c) => WhatADealScreen(message: "Selamat! ${widget.trade.title} telah menjadi milik Anda."))
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => errorMessage = "Gagal memproses redeem. Coba lagi nanti.");
    }
  }

  Widget _buildTradeImage() {
    String path = widget.trade.image;
    
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: path.startsWith('http') 
          ? Image.network(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            )
          : Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int reqPoint = _calculateReqPoint();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isAvatar ? "Redeem Avatar" : "Redeem Reward", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                  Text(widget.trade.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                  const SizedBox(height: 10),
                  Text(widget.trade.description, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.orange, size: 30),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Poin Anda Saat Ini", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text("${user.points ?? 0} Poin", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text("Syarat Penukaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  
                  _buildRequirementTile(Icons.monetization_on_rounded, "$reqPoint Poin", (user.points ?? 0) >= reqPoint),
                  
                  if (!isAvatar) ...[
                    _buildRequirementTile(
                      Icons.verified_rounded, 
                      "1x Badge ${widget.trade.requiredBadgeType}", 
                      userOwnedBadges.isNotEmpty
                    ),
                    const SizedBox(height: 25),
                    const Text("Pilih Badge untuk Ditukarkan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    userOwnedBadges.isEmpty 
                      ? const Text("Maaf, Anda tidak memiliki badge yang diperlukan.", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: userOwnedBadges.map((ub) => ChoiceChip(
                            label: Text(ub.badge?.name ?? "Badge"),
                            selected: selectedBadgeToTrade == ub,
                            selectedColor: AppColors.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryColor,
                            labelStyle: TextStyle(color: selectedBadgeToTrade == ub ? AppColors.primaryColor : Colors.black87, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              setState(() => selectedBadgeToTrade = val ? ub : null);
                            },
                          )).toList(),
                        ),
                  ],

                  const SizedBox(height: 40),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (!widget.trade.hasTrade && _isPurchaseValid()) ? _processRedeem : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      child: Text(
                        widget.trade.hasTrade ? "SUDAH DIMILIKI" : "KONFIRMASI PENUKARAN", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementTile(IconData icon, String label, bool isMet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMet ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isMet ? Colors.green : Colors.red, size: 22),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 15, color: isMet ? Colors.black87 : Colors.grey, fontWeight: isMet ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}