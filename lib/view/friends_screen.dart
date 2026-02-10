import 'package:app/service/user_service.dart';
import 'package:app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../model/user.dart';

Color purple = Color(0xFF441F7F);
Color backgroundNavHex = Color(0xFFF3EDF7);
const url = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _FriendsScreen();
}

class _FriendsScreen extends State<FriendsScreen> {
  List<Student> user = [];

  List<Student> sortUserbyPoint(List<Student> list) {
    list.sort((a, b) => b.points!.compareTo(a.points!));
    return list;
  }

  List<Student> studentRole(List<Student> list) {
    return list.where((user) => user.role == 'STUDENT').toList();
  }

  void getAllUser() async {
    final result = await UserService.getAllUser();
    if (mounted) {
      setState(() {
        user = sortUserbyPoint(studentRole(result));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAllUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A206C),
      body: Stack(
        children: [
          // 1. BACKGROUND FULL LAYAR
          // Menggunakan Positioned.fill agar gambar tidak hanya berada di bagian atas
          Positioned.fill(
            child: Image.asset(
              "lib/assets/gamification.jpeg",
              fit: BoxFit.cover, 
              alignment: Alignment.topCenter,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
          ),
          
          Column(
            children: [
              // Header - Diturunkan agar seimbang
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 50), 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'lib/assets/pictures/icon.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Papan Peringkat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'DIN_Next_Rounded',
                                  ),
                                ),
                                Text(
                                  'Kompetisi mingguan',
                                  style: TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 13,
                                    fontFamily: 'DIN_Next_Rounded',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // Leaderboard Podium
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAttractivePodiumItem(user, 1, 'lib/assets/leaderboards/banner-silver.png', const Color(0xFF6B7280)),
                    _buildAttractivePodiumItem(user, 0, 'lib/assets/leaderboards/banner-gold.png', const Color(0xFFF59E0B)),
                    _buildAttractivePodiumItem(user, 2, 'lib/assets/leaderboards/banner-bronze.png', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // 2. LIST PERINGKAT PANEL BAWAH
              // Dibuat transparan (Opacity 0.9) agar gambar sirkuit background tembus ke bawah
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), 
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAttractiveSectionHeader(),
                      const SizedBox(height: 15),
                      Expanded(child: _buildAttractiveFriendsList()),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttractivePodiumItem(List<Student> list, int index, String bannerPath, Color color) {
    final student = list.isNotEmpty && list.length > index ? list[index] : null;
    final heights = [65, 55, 45];
    final height = heights[index];
    
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index == 2) const SizedBox(height: 35),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: student?.image != null && student!.image!.isNotEmpty
                  ? NetworkImage(student.image!)
                  : null,
              child: student?.image == null || student!.image!.isEmpty
                  ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              student?.name ?? '',
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                fontFamily: 'DIN_Next_Rounded',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 7,
                ),
                const SizedBox(width: 1),
                Text(
                  '${student?.points ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'DIN_Next_Rounded',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 55,
            height: height.toDouble(),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bannerPath),
                fit: BoxFit.fitWidth,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              index == 0 ? '1ST' : index == 1 ? '2ND' : '3RD',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'DIN_Next_Rounded',
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractiveSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF441F7F).withOpacity(0.1),
              const Color(0xFF6B46C1).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF441F7F).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF441F7F).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF441F7F),
                    const Color(0xFF6B46C1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF441F7F).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua Peserta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'DIN_Next_Rounded',
                    ),
                  ),
                  Text(
                    'Daftar lengkap kompetitor',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'DIN_Next_Rounded',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF441F7F),
                    const Color(0xFF6B46C1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF441F7F).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${user.length} peserta',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DIN_Next_Rounded',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttractiveFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: user.length,
      itemBuilder: (context, index) {
        return _buildAttractiveFriendCard(user[index], index);
      },
    );
  }

  Widget _buildAttractiveFriendCard(Student student, int index) {
    final isTopThree = index < 3;
    final isFirst = index == 0;
    
    final rankColors = [
      const Color(0xFFFFD700), // Emas
      const Color(0xFFC0C0C0), // Perak
      const Color(0xFFCD7F32), // Perunggu
    ];
    
    final rankColor = isTopThree ? rankColors[index] : const Color(0xFF6B7280);
    
    final List<Color> cardGradient = switch (index) {
        0 => [const Color(0xFFFFFBEB), Colors.white], 
        1 => [const Color(0xFFF9FAFB), Colors.white], 
        2 => [const Color(0xFFFEF2F2), Colors.white],
        _ => [Colors.white, Colors.white],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isFirst)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 0),
            ),
        ],
        border: isTopThree ? Border.all(
          color: rankColor.withOpacity(0.3),
          width: 1.5,
        ) : Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isTopThree 
                    ? [rankColor, rankColor.withOpacity(0.7)]
                    : [const Color(0xFF441F7F), const Color(0xFF6B46C1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isTopThree ? rankColor.withOpacity(0.4) : const Color(0xFF441F7F).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isTopThree
                  ? Icon(
                      switch (index) {
                        0 => Icons.emoji_events_rounded,
                        1 => Icons.military_tech_rounded,
                        2 => Icons.workspace_premium_rounded,
                        _ => Icons.star,
                      },
                      color: Colors.white,
                      size: 28,
                    )
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'DIN_Next_Rounded',
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF3EDF7),
                        backgroundImage: student.image != null && student.image!.isNotEmpty
                            ? NetworkImage(student.image!)
                            : null,
                        child: student.image == null || student.image!.isEmpty
                            ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                                fontFamily: 'DIN_Next_Rounded',
                              ),
                            ),
                            Text(
                              student.studentId ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontFamily: 'DIN_Next_Rounded',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isTopThree)
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 200 + (i * 150)),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 0.2,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    i < 3 ? Icons.star_rounded : Icons.diamond_rounded,
                                    color: rankColor,
                                    size: 10 + (value * 4),
                                  ),
                                ),
                              );
                            },
                          ),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      rankColor,
                                      rankColor.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rankColor.withOpacity(value * 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        for (int i = 0; i < 2; i++)
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 400 + (i * 200)),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.circle,
                                    color: const Color(0xFF441F7F).withOpacity(0.6),
                                    size: 6,
                                  ),
                                ),
                              );
                            },
                          ),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF441F7F).withOpacity(value * 0.4),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF441F7F),
                    const Color(0xFF6B46C1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF441F7F).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${student.points}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'DIN_Next_Rounded',
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
}