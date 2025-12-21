// lib/view/trade_detail_screen.dart
import 'package:app/model/trade.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/trade_service.dart';
import 'package:app/service/user_badge_service.dart';
import 'package:app/service/user_service.dart';
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
  List<UserBadge> userBadges = [];
  List<UserBadge> selectedBadges = [];
  String errorMessage = '';
  late Student user; // Menggunakan late karena diinisialisasi di initState

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
      _fetchUserBadges();
    }
  }

  Future<void> _fetchUserBadges() async {
    try {
      final result = await BadgeService.getUserBadgeListByUserId(user.id);
      setState(() {
        userBadges = result.where((b) => !b.isPurchased).toList();
      });
    } catch (e) {
      debugPrint("Error: $e");
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
    // Perbaikan error 82: Mengganti ?. menjadi . karena user bukan null
    if ((user.points ?? 0) < reqPoint) return false;
    if (isAvatar) return true;
    if (selectedBadges.isEmpty) return false;
    return selectedBadges.first.badge?.type.toUpperCase() == widget.trade.requiredBadgeType.toUpperCase();
  }

  Future<void> _purchase() async {
    int reqPoint = _calculateReqPoint();
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    try {
      bool success = await TradeService.createUserTrade(user.id, widget.trade.id);
      if (success) {
        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);
        if (!isAvatar && selectedBadges.isNotEmpty) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadges.first.id, true);
        }
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (c) => WhatADealScreen(message: "Sukses! Anda mendapatkan ${widget.trade.title}"))
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => errorMessage = "Gagal memproses transaksi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    int reqPoint = _calculateReqPoint();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Detail"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: Image.network(
                widget.trade.image,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Gambar gagal dimuat", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trade.title, 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor)
                  ),
                  const SizedBox(height: 10),
                  Container(
                    // Perbaikan error 164: Mengganti 'py' menjadi 'vertical'
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // Perbaikan error 166: Mengganti withOpacity menjadi withAlpha atau Values (sesuai SDK baru)
                      color: AppColors.primaryColor.withAlpha(25), 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      // Perbaikan error 192: Mengganti ?. menjadi .
                      "Poin Saya: ${user.points ?? 0}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)
                    ),
                  ),
                  const Divider(height: 40),
                  const Text("Syarat Penukaran:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    isAvatar 
                      ? "• Tukarkan $reqPoint Poin" 
                      : "• Tukarkan $reqPoint Poin\n• 1x Badge ${widget.trade.requiredBadgeType}",
                    style: const TextStyle(height: 1.5),
                  ),
                  if (!isAvatar) ...[
                    const SizedBox(height: 25),
                    const Text("Pilih Badge yang Ingin Ditukar:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    userBadges.isEmpty 
                      ? const Text("Anda tidak memiliki badge yang sesuai.", style: TextStyle(color: Colors.red, fontSize: 12))
                      : Wrap(
                          spacing: 8,
                          children: userBadges.map((ub) => ChoiceChip(
                            label: Text(ub.badge?.name ?? ""),
                            selected: selectedBadges.contains(ub),
                            // Perbaikan error 194: Mengganti withOpacity menjadi withAlpha
                            selectedColor: AppColors.primaryColor.withAlpha(75),
                            onSelected: (val) => setState(() {
                              selectedBadges.clear();
                              if (val) selectedBadges.add(ub);
                            }),
                          )).toList(),
                        ),
                  ],
                  const SizedBox(height: 40),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (!widget.trade.hasTrade && _isPurchaseValid()) ? _purchase : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(
                        widget.trade.hasTrade ? "SUDAH DIMILIKI" : "REDEEM SEKARANG", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}