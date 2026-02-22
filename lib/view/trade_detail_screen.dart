import 'package:app/model/trade.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/user_badge_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/view/whatadeal_screen.dart';
import 'package:app/global_var.dart'; // Tambahkan ini
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

  bool get isAvatar => widget.trade.category == "AVATAR";
  bool get isFrame => widget.trade.category == "FRAME" || widget.trade.image.toLowerCase().contains('frame');
  bool get isShopItem => widget.trade.requiredBadgeType == null || widget.trade.requiredBadgeType!.isEmpty || isFrame;

  @override
  void initState() {
    user = widget.user;
    _initData();
    super.initState();
  }

  Future<void> _initData() async {
    pref = await SharedPreferences.getInstance();
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
    if (isAvatar) {
      final Map<int, int> prices = { 1: 0, 2: 100, 3: 100, 4: 100, 5: 200, 6: 200, 7: 250, 8: 250, 9: 300, 10: 300, 11: 350, 12: 350 };
      return prices[widget.trade.id] ?? 500;
    }
    if (isFrame || widget.trade.priceInPoints > 0) {
      return widget.trade.priceInPoints > 0 ? widget.trade.priceInPoints : 2500;
    }
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
    if (isAvatar || isShopItem) return true;
    if (selectedBadgeToTrade == null) return false;
    return true;
  }

  Future<void> _processRedeem() async {
    int reqPoint = _calculateReqPoint();
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      bool success = false;
      if (isAvatar || isShopItem) {
        success = await TradeService.buyShopItem(user.id, widget.trade.id, reqPoint);
      } else {
        success = await TradeService.createUserTrade(user.id, widget.trade.id);
      }
      
      if (success) {
        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);

        if (!isAvatar && !isShopItem && selectedBadgeToTrade != null) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadgeToTrade!.id, true);
        }

        if (!mounted) return;
        Navigator.pop(context); 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => WhatADealScreen(message: "Sukses! ${widget.trade.title} didapatkan.")));
      } else {
        throw Exception("Transaksi gagal diproses.");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
                  Text(widget.trade.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
                  const SizedBox(height: 10),
                  Text(widget.trade.description, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 30),
                  _buildRequirementCard(reqPoint),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.monetization_on, color: hasEnoughPoints ? Colors.green : Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text("Harga: $reqPoint Poin\n(Poin Anda: ${user.points})", style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          if (!isAvatar && !isShopItem) ...[
            const Divider(height: 30),
            Row(children: [
              Icon(Icons.verified, color: userOwnedBadges.isNotEmpty ? Colors.blue : Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text("Butuh: 1x Lencana ${widget.trade.requiredBadgeType}", style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ]
        ],
      ),
    );
  }

  Widget _buildTradeImage() {
    bool isLocalFrame = isFrame;
    String path = widget.trade.image;

    return Container(
      height: 280, 
      width: double.infinity, 
      color: Colors.white,
      padding: const EdgeInsets.all(30),
      child: Hero(
        tag: widget.trade.id,
        child: isLocalFrame
            ? Image.asset(
                path.startsWith('lib/assets') ? path : 'lib/assets/Frames/${path.replaceAll('.png', '')}.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              )
            : Image.network(
                GlobalVar.formatImageUrl(path), 
                fit: BoxFit.contain, 
                errorBuilder: (c, e, s) => const Icon(Icons.face, size: 100, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildBadgePicker() {
    if (userOwnedBadges.isEmpty) {
      return const Text("Maaf, Anda tidak memiliki lencana yang sesuai.", style: TextStyle(color: Colors.red, fontSize: 13));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: userOwnedBadges.map((ub) {
        return ChoiceChip(
          label: Text(ub.badge?.name ?? "Lencana"),
          selected: selectedBadgeToTrade == ub,
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          onSelected: (val) => setState(() => selectedBadgeToTrade = val ? ub : null),
        );
      }).toList(),
    );
  }

  Widget _buildRedeemButton() {
    bool canRedeem = !widget.trade.hasTrade && _isPurchaseValid();
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor, 
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: canRedeem ? _processRedeem : null,
        child: Text(
          widget.trade.hasTrade ? "SUDAH DIMILIKI" : (isAvatar || isFrame ? "BELI SEKARANG" : "TUKAR REWARD"), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        ),
      ),
    );
  }
}