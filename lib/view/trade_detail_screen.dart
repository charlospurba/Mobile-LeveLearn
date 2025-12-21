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
  List<UserBadge> userOwnedBadges = [];
  UserBadge? selectedBadgeToTrade;
  String errorMessage = '';
  late Student user;

  // Logika: Jika judul mengandung 'avatar', maka ini adalah item koleksi profile.
  // Jika tidak, maka ini adalah Reward/Merchandise yang butuh tukar badge.
  bool get isAvatar => widget.trade.title.toLowerCase().contains("avatar");

  @override
  void initState() {
    user = widget.user;
    _initData();
    super.initState();
  }

  Future<void> _initData() async {
    pref = await SharedPreferences.getInstance();
    // Jika bukan avatar (berarti Reward), kita ambil daftar badge yang dimiliki user untuk ditukarkan
    if (!isAvatar) {
      _fetchAvailableBadgesForTrade();
    }
  }

  Future<void> _fetchAvailableBadgesForTrade() async {
    try {
      final result = await BadgeService.getUserBadgeListByUserId(user.id);
      setState(() {
        // Ambil badge yang belum pernah dikorbankan/digunakan untuk trade (isPurchased = false)
        // Dan tipenya harus sama dengan yang diminta oleh Trade Model
        userOwnedBadges = result.where((b) => 
          !b.isPurchased && 
          b.badge!.type.toUpperCase() == widget.trade.requiredBadgeType.toUpperCase()
        ).toList();
      });
    } catch (e) {
      debugPrint("Error Fetching Badges: $e");
    }
  }

  // Menghitung harga poin berdasarkan ID Trade (Khusus Avatar) atau Tipe Badge (Khusus Reward)
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
      // Reward membutuhkan Poin + Badge
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
    
    // 1. Cek kecukupan poin (Berlaku untuk Avatar & Reward)
    if ((user.points ?? 0) < reqPoint) return false;

    // 2. Cek syarat tambahan jika ini adalah Reward (Bukan Avatar)
    if (!isAvatar) {
      // Reward wajib pilih 1 badge untuk ditukarkan
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
      // 1. Catat transaksi di tabel UserTrade
      bool success = await TradeService.createUserTrade(user.id, widget.trade.id);
      
      if (success) {
        // 2. Potong poin user
        user.points = (user.points ?? 0) - reqPoint;
        await UserService.updateUserPoints(user);

        // 3. Jika ini Reward, tandai badge yang dipilih sebagai "Sudah Digunakan/Dikonsumsi"
        if (!isAvatar && selectedBadgeToTrade != null) {
          await UserBadgeService.updateUserBadgeStatus(selectedBadgeToTrade!.id, true);
        }

        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        
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

  @override
  Widget build(BuildContext context) {
    int reqPoint = _calculateReqPoint();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAvatar ? "Redeem Avatar" : "Redeem Reward"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Image
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: Image.network(
                widget.trade.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.trade.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                  const SizedBox(height: 8),
                  Text(widget.trade.description, style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 40),
                  
                  // Statistik Poin
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text("Poin Anda: ${user.points ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Syarat Section
                  Text("Syarat Penukaran:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])),
                  const SizedBox(height: 10),
                  
                  // Label Harga Poin
                  _buildRequirementTile(Icons.monetization_on, "$reqPoint Poin", (user.points ?? 0) >= reqPoint),
                  
                  // Label Syarat Badge (Hanya muncul jika Reward)
                  if (!isAvatar) ...[
                    _buildRequirementTile(
                      Icons.verified, 
                      "1x Badge ${widget.trade.requiredBadgeType}", 
                      userOwnedBadges.isNotEmpty
                    ),
                    const SizedBox(height: 20),
                    const Text("Pilih Badge yang akan ditukar:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    userOwnedBadges.isEmpty 
                      ? const Text("Anda tidak memiliki badge yang diperlukan.", style: TextStyle(color: Colors.red, fontSize: 13))
                      : Wrap(
                          spacing: 8,
                          children: userOwnedBadges.map((ub) => ChoiceChip(
                            label: Text(ub.badge?.name ?? "Badge"),
                            selected: selectedBadgeToTrade == ub,
                            selectedColor: AppColors.primaryColor.withAlpha(50),
                            onSelected: (val) {
                              setState(() => selectedBadgeToTrade = val ? ub : null);
                            },
                          )).toList(),
                        ),
                  ],

                  const SizedBox(height: 40),
                  if (errorMessage.isNotEmpty)
                    Text(errorMessage, style: const TextStyle(color: Colors.red)),

                  // Button Action
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (!widget.trade.hasTrade && _isPurchaseValid()) ? _processRedeem : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(
                        widget.trade.hasTrade ? "SUDAH DIMILIKI" : "KONFIRMASI REDEEM", 
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.cancel, color: isMet ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(decoration: isMet ? null : TextDecoration.lineThrough)),
        ],
      ),
    );
  }
}