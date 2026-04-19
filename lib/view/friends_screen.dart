import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/global_var.dart';
import 'package:app/service/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user.dart';

// --- PALET WARNA ---
Color purple = const Color(0xFF441F7F);
Color softPurple = const Color(0xFFF3EDF7);
Color gold = const Color(0xFFFFD700);
Color silver = const Color(0xFFC0C0C0);
Color bronze = const Color(0xFFCD7F32);

// (Model CommentModel & Post tetap sama seperti sebelumnya)
class CommentModel {
  final String userName;
  final String? userImage;
  final String content;
  CommentModel({required this.userName, this.userImage, required this.content});
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return CommentModel(
      userName: user?['name'] ?? 'User',
      userImage: user?['image'],
      content: json['content'] ?? '',
    );
  }
}

class Post {
  final int id;
  final int userId;
  final String userName;
  final String? userImage;
  final String? content;
  final String? link;
  final String? fileUrl;
  final String? fileName;
  final String createdAt;
  int likeCount;
  int commentCount;
  bool isLiked;
  List<CommentModel> comments;

  Post({
    required this.id, required this.userId, required this.userName, this.userImage,
    required this.content, this.link, this.fileUrl, this.fileName, required this.createdAt,
    required this.likeCount, required this.commentCount, required this.isLiked, required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    return Post(
      id: json['id'] ?? 0,
      userId: userData?['id'] ?? 0,
      userName: userData?['name'] ?? 'Anonymous',
      userImage: userData?['image'],
      content: json['content'],
      link: json['link'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      likeCount: json['_count']?['likes'] ?? 0,
      commentCount: json['_count']?['comments'] ?? 0,
      isLiked: (json['likes'] as List?)?.isNotEmpty ?? false,
      comments: (json['comments'] as List?)?.map((c) => CommentModel.fromJson(c)).toList() ?? [],
    );
  }
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<StatefulWidget> createState() => _FriendsScreen();
}

class _FriendsScreen extends State<FriendsScreen> {
  List<Student> leaderboard = [];
  List<Post> posts = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int activeId = 0;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        activeId = prefs.getInt('userId') ?? 0;
        posts = [];
      });
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_fetchLeaderboard(), _fetchPosts()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchLeaderboard() async {
    final result = await UserService.getAllUser();
    if (mounted) {
      var filtered = result.where((u) => u.role == 'STUDENT').toList();
      filtered.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
      setState(() => leaderboard = filtered.take(10).toList());
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts?currentUserId=$activeId"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) setState(() => posts = data.map((json) => Post.fromJson(json)).toList());
      }
    } catch (e) { debugPrint("Fetch error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: purple,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text("Share Something", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Background Gradient yang lebih proporsional
          Container(
            height: 400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [purple, const Color(0xFF2D1454)],
              ),
            ),
          ),
          _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _initSession,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- PERBAIKAN APPBAR (LOGO POSISI) ---
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: purple,
                    centerTitle: true,
                    toolbarHeight: 70, // Memberikan ruang agar logo tidak terlalu mepet ke atas
                    title: Padding(
                      padding: const EdgeInsets.only(top: 20.0), // Menurunkan posisi logo
                      child: Image.asset("lib/assets/LeveLearn.png", width: 130),
                    ),
                  ),
                  
                  // --- SECTION 1: PODIUM ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
                      child: SizedBox(
                        height: 250, 
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (leaderboard.length > 1) _buildPodiumItem(leaderboard[1], 1, 'lib/assets/leaderboards/banner-silver.png', silver, 80),
                            if (leaderboard.isNotEmpty) _buildPodiumItem(leaderboard[0], 0, 'lib/assets/leaderboards/banner-gold.png', gold, 110),
                            if (leaderboard.length > 2) _buildPodiumItem(leaderboard[2], 2, 'lib/assets/leaderboards/banner-bronze.png', bronze, 70),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- SECTION 2: CONTENT ---
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 25),
                          _buildSectionHeader("Elite Leaderboard", Icons.workspace_premium, "Top students ranking"),
                          _buildFancyLeaderboardList(),
                          const SizedBox(height: 30),
                          _buildSectionHeader("Global Community Feed", Icons.public, "Stay updated with your peers"),
                          if (_isUploading) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: LinearProgressIndicator()),
                          _buildPostList(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- PODIUM ITEM ---
  Widget _buildPodiumItem(Student s, int index, String bannerPath, Color color, double tiangHeight) {
    double avatarRadius = index == 0 ? 42.0 : 34.0;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: avatarRadius + 3,
            backgroundColor: color,
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              backgroundImage: (s.image != null && s.image!.isNotEmpty) ? NetworkImage(s.image!) : null,
              child: (s.image == null || s.image!.isEmpty) ? Icon(Icons.person, color: color, size: avatarRadius) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          Text("${s.points} XP", style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 10),
          SizedBox(
            height: tiangHeight, 
            child: Image.asset(bannerPath, fit: BoxFit.contain)
          ),
        ],
      ),
    );
  }

  // (Helper UI lainnya: _buildSectionHeader, _buildFancyLeaderboardList, _buildPostList, _buildPostCard, _showCreatePostSheet, dll)
  // Tetap gunakan logika dari jawaban sebelumnya karena sudah stabil.

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: softPurple, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: purple, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFancyLeaderboardList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: leaderboard.asMap().entries.map((entry) {
          int idx = entry.key;
          var s = entry.value;
          Color rColor = idx == 0 ? gold : (idx == 1 ? silver : (idx == 2 ? bronze : softPurple));
          return ListTile(
            leading: CircleAvatar(
              radius: 14, backgroundColor: rColor.withOpacity(0.2),
              child: Text("${idx + 1}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: idx < 3 ? Colors.black87 : purple)),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: Text("${s.points} XP", style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 13)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostList() {
    if (posts.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No posts available.")));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostCard(posts[index]),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildSafeAvatar(post.userImage, radius: 22),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.createdAt.split('T')[0], style: const TextStyle(fontSize: 11)),
            trailing: post.userId == activeId 
              ? PopupMenuButton<String>(
                  onSelected: (val) => val == 'edit' ? _showEditDialog(post) : _showDeleteConfirm(post.id),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                    const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                  ],
                )
              : null,
          ),
          if (post.content != null && post.content!.isNotEmpty) 
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(post.content!)),
          _buildOptimizedMedia(post),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : Colors.grey,
                  label: "${post.likeCount}",
                  onTap: () => _handleLike(post),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.grey,
                  label: "${post.commentCount}",
                  onTap: () => _showCommentSheet(post),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.share_outlined, size: 20), onPressed: () => Share.share("Check out ${post.userName}'s post!")),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- HELPER LAIN ---
  Widget _buildSafeAvatar(String? url, {double radius = 16}) {
    if (url == null || url.isEmpty || !url.startsWith("http")) return CircleAvatar(radius: radius, child: const Icon(Icons.person, size: 18));
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 5), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))])));
  }

  // ... (Fungsi _handleLike, _showEditDialog, _showDeleteConfirm, _showCreatePostSheet, _showCommentSheet, _buildOptimizedMedia tetap sama)
  // Sertakan fungsi tersebut untuk melengkapi code ini.
  
  Future<void> _handleLike(Post post) async {
    if (activeId == 0) return;
    bool originalStatus = post.isLiked;
    setState(() { post.isLiked = !post.isLiked; post.isLiked ? post.likeCount++ : post.likeCount--; });
    try { await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/like"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"userId": activeId, "postId": post.id})); } catch (e) { if (mounted) setState(() { post.isLiked = originalStatus; originalStatus ? post.likeCount : post.likeCount; }); }
  }

  void _showEditDialog(Post post) {
    TextEditingController editCtrl = TextEditingController(text: post.content);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Edit Post"), content: TextField(controller: editCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () async { await http.put(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts/${post.id}"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"userId": activeId, "content": editCtrl.text})); Navigator.pop(ctx); _initSession(); }, child: const Text("Save"))]));
  }

  void _showDeleteConfirm(int postId) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Delete Post?"), content: const Text("Action cannot be undone."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), TextButton(onPressed: () async { await http.delete(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts/$postId"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"userId": activeId})); Navigator.pop(ctx); _initSession(); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))]));
  }

  void _showCreatePostSheet() {
    TextEditingController contentCtrl = TextEditingController();
    TextEditingController linkCtrl = TextEditingController();
    PlatformFile? pickedFile;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Create New Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15), TextField(controller: contentCtrl, maxLines: 4, decoration: InputDecoration(hintText: "What's on your mind?", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))), const SizedBox(height: 10), TextField(controller: linkCtrl, decoration: const InputDecoration(hintText: "YouTube link (optional)", prefixIcon: Icon(Icons.link))), const SizedBox(height: 10), if (pickedFile != null) ListTile(leading: const Icon(Icons.attach_file), title: Text(pickedFile!.name), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setModalState(() => pickedFile = null))), Row(children: [IconButton(onPressed: () async { var res = await FilePicker.platform.pickFiles(withData: true); if (res != null) setModalState(() => pickedFile = res.files.first); }, icon: Icon(Icons.add_a_photo, color: purple)), const Spacer(), ElevatedButton(onPressed: () async { if (contentCtrl.text.isEmpty && pickedFile == null) return; Navigator.pop(ctx); setState(() => _isUploading = true); String? supabaseUrl; if (pickedFile != null) { final String storagePath = 'community/${activeId}_${DateTime.now().millisecondsSinceEpoch}'; await Supabase.instance.client.storage.from('Postingan').uploadBinary(storagePath, pickedFile!.bytes!); supabaseUrl = Supabase.instance.client.storage.from('Postingan').getPublicUrl(storagePath); } await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"userId": activeId, "content": contentCtrl.text, "link": linkCtrl.text, "fileUrl": supabaseUrl, "fileName": pickedFile?.name})); _initSession(); setState(() => _isUploading = false); }, style: ElevatedButton.styleFrom(backgroundColor: purple), child: const Text("Post Now", style: TextStyle(color: Colors.white)))])]))));
  }

  void _showCommentSheet(Post post) {
    TextEditingController ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(height: MediaQuery.of(context).size.height * 0.7, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Column(children: [const Padding(padding: EdgeInsets.all(15), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const Divider(), Expanded(child: ListView.builder(padding: const EdgeInsets.all(15), itemCount: post.comments.length, itemBuilder: (ctx, i) => ListTile(leading: _buildSafeAvatar(post.comments[i].userImage, radius: 18), title: Text(post.comments[i].userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(post.comments[i].content)))), Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 15, left: 15, right: 15), child: Row(children: [Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Add a comment..."))), IconButton(icon: Icon(Icons.send, color: purple), onPressed: () async { if (ctrl.text.isEmpty) return; await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/comment"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"userId": activeId, "postId": post.id, "content": ctrl.text})); Navigator.pop(context); _initSession(); })]))])));
  }

  Widget _buildOptimizedMedia(Post post) {
    if (post.link != null && post.link!.contains("youtube")) {
      String? vId = YoutubePlayer.convertUrlToId(post.link!);
      if (vId != null) return InkWell(onTap: () => launchUrl(Uri.parse(post.link!)), child: Container(height: 180, width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage("https://img.youtube.com/vi/$vId/0.jpg"), fit: BoxFit.cover))));
    }
    if (post.fileUrl != null && post.fileUrl!.startsWith("http")) {
      if (post.fileName?.endsWith(".pdf") ?? false) {
        return ListTile(leading: const Icon(Icons.picture_as_pdf, color: Colors.red), title: const Text("Open PDF Document"), onTap: () => launchUrl(Uri.parse(post.fileUrl!)));
      }
      return Image.network(post.fileUrl!, width: double.infinity, fit: BoxFit.fitWidth);
    }
    return const SizedBox.shrink();
  }
}