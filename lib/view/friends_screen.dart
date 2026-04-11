import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:app/global_var.dart';
import 'package:app/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../model/user.dart';

// --- PALET WARNA ---
Color purple = const Color(0xFF441F7F);
Color softPurple = const Color(0xFFF3EDF7);
Color gold = const Color(0xFFFFD700);
Color silver = const Color(0xFFC0C0C0);
Color bronze = const Color(0xFFCD7F32);

// === MODELS ===
class CommentModel {
  final String userName;
  final String? userImage;
  final String content;
  final String createdAt;

  CommentModel({required this.userName, this.userImage, required this.content, required this.createdAt});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      userName: json['user']?['name'] ?? 'User',
      userImage: json['user']?['image'],
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class Post {
  final int id;
  final String userName;
  final String? userImage;
  final String? userFrame;
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
    required this.id, required this.userName, this.userImage, this.userFrame,
    this.content, this.link, this.fileUrl, this.fileName, required this.createdAt,
    required this.likeCount, required this.commentCount, required this.isLiked, required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    String? frame;
    if (userData != null && userData['userTrades'] != null) {
      final trades = userData['userTrades'] as List;
      if (trades.isNotEmpty) frame = trades[0]['trade']?['image'];
    }
    return Post(
      id: json['id'] ?? 0,
      userName: userData?['name'] ?? 'Anonymous',
      userImage: userData?['image'],
      userFrame: frame,
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
  final int currentUserId = 5; 

  @override
  void initState() {
    super.initState();
    _refreshData();
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
      final response = await http.get(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts?currentUserId=$currentUserId"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) setState(() => posts = data.map((json) => Post.fromJson(json)).toList());
      }
    } catch (e) { debugPrint("Fetch error: $e"); }
  }

  Future<void> _handleLike(Post post) async {
    setState(() {
      if (post.isLiked) post.likeCount--; else post.likeCount++;
      post.isLiked = !post.isLiked;
    });
    try {
      await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/like"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"userId": currentUserId, "postId": post.id}));
    } catch (e) { _fetchPosts(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: purple,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("Buat Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [purple, const Color(0xFF2D1454), Colors.white],
                stops: const [0.0, 0.4, 0.6],
              ),
            ),
          ),
          _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  // --- SECTION 1: PODIUM ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: SizedBox(
                        height: 220,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (leaderboard.length > 1) _buildAttractivePodiumItem(leaderboard[1], 1, 'lib/assets/leaderboards/banner-silver.png', silver),
                            if (leaderboard.isNotEmpty) _buildAttractivePodiumItem(leaderboard[0], 0, 'lib/assets/leaderboards/banner-gold.png', gold),
                            if (leaderboard.length > 2) _buildAttractivePodiumItem(leaderboard[2], 2, 'lib/assets/leaderboards/banner-bronze.png', bronze),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // --- SECTION 2: WHITE CONTENT AREA ---
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSectionHeader("Papan Juara LeveLearn", Icons.workspace_premium, "${leaderboard.length} Peserta"),
                          _buildFancyLeaderboardList(),
                          const SizedBox(height: 30),
                          _buildSectionHeader("Community Feed", Icons.forum, "Terbaru"),
                          if (_isUploading) _buildUploadProgress(),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80.0, pinned: true, elevation: 0, backgroundColor: purple,
      flexibleSpace: FlexibleSpaceBar(centerTitle: true, title: Image.asset("lib/assets/LeveLearn.png", width: 140)),
    );
  }

  Widget _buildAttractivePodiumItem(Student s, int index, String bannerPath, Color color) {
    double avatarRadius = index == 0 ? 38.0 : 31.0;
    return Flexible(
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
              child: s.image == null ? Icon(Icons.person, color: color) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1),
          Text("${s.points} pts", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 4),
          SizedBox(height: index == 0 ? 100 : 80, child: Image.asset(bannerPath, fit: BoxFit.contain)),
        ],
      ),
    );
  }

  Widget _buildFancyLeaderboardList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leaderboard.length,
        itemBuilder: (context, i) {
          final student = leaderboard[i];
          Color rColor = i == 0 ? gold : (i == 1 ? silver : (i == 2 ? bronze : Colors.grey.shade400));
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: i < 3 ? rColor.withOpacity(0.2) : softPurple, 
                child: i < 3 
                    ? Icon(Icons.emoji_events, color: rColor, size: 20)
                    : Text("${i + 1}", style: TextStyle(color: purple, fontWeight: FontWeight.bold))
              ),
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("${student.points} pts", style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostList() {
    if (posts.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Text("Belum ada postingan komunitas."));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(backgroundImage: post.userImage != null ? NetworkImage(post.userImage!) : null),
                title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_formatTime(DateTime.parse(post.createdAt))),
                trailing: IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () => Share.share("${post.content}\n\nLihat di LeveLearn!")),
              ),
              if (post.content != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(post.content!)),
              
              // --- MEDIA CONTENT HANDLER (YouTube / File / Link) ---
              _buildMediaContent(post),

              const Divider(),
              Row(
                children: [
                  const SizedBox(width: 10),
                  TextButton.icon(onPressed: () => _handleLike(post), icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : Colors.grey), label: Text("${post.likeCount}")),
                  TextButton.icon(onPressed: () => _showCommentSheet(post), icon: const Icon(Icons.chat_bubble_outline), label: Text("${post.commentCount}")),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaContent(Post post) {
    // 1. Prioritas: Cek Link YouTube
    if (post.link != null && (post.link!.contains("youtube.com") || post.link!.contains("youtu.be"))) {
      String? videoId = YoutubePlayer.convertUrlToId(post.link!);
      if (videoId != null) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: false)),
              showVideoProgressIndicator: true,
            ),
          ),
        );
      }
    }

    // 2. Tampilkan Link Biasa jika bukan YouTube
    if (post.link != null && post.link!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(post.link!), mode: LaunchMode.externalApplication),
          child: Row(children: [
            const Icon(Icons.link, color: Colors.blue, size: 18),
            const SizedBox(width: 5),
            Expanded(child: Text(post.link!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis))
          ]),
        ),
      );
    }

    // 3. Tampilkan File Preview (PDF/Image/Video Upload)
    if (post.fileUrl != null) {
      final String encodedUrl = Uri.encodeFull(post.fileUrl!);
      final String fileName = post.fileName?.toLowerCase() ?? "";
      bool isPdf = fileName.endsWith(".pdf");
      bool isImage = fileName.endsWith(".jpg") || fileName.endsWith(".png") || fileName.endsWith(".jpeg");
      bool isVideo = fileName.endsWith(".mp4") || fileName.endsWith(".mov");

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.3))),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 350,
                width: double.infinity,
                child: isPdf 
                  ? SfPdfViewer.network(encodedUrl) // PDF Content Inline
                  : isImage 
                    ? Image.network(encodedUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)))
                    : isVideo 
                      ? InlineVideoPlayer(url: encodedUrl) // MP4/MOV Player
                      : WebViewWidget( // Fallback Office Files
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadRequest(Uri.parse("https://docs.google.com/viewer?url=$encodedUrl&embedded=true")),
                        ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade900,
                child: Row(children: [
                  Expanded(child: Text(post.fileName ?? "Dokumen", style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.remove_red_eye, color: Colors.white, size: 18),
                ]),
              )
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }

  void _showCreatePostSheet() {
    TextEditingController contentCtrl = TextEditingController();
    TextEditingController linkCtrl = TextEditingController();
    PlatformFile? pickedFile;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Buat Postingan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(hintText: "Tulis sesuatu...", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: linkCtrl, decoration: const InputDecoration(hintText: "Link YouTube/Tautan", prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 10),
            if (pickedFile != null) ListTile(leading: const Icon(Icons.attach_file), title: Text(pickedFile!.name)),
            TextButton.icon(
              onPressed: () async {
                var res = await FilePicker.platform.pickFiles(withData: true);
                if (res != null) setModalState(() => pickedFile = res.files.first);
              },
              icon: const Icon(Icons.add_a_photo), label: const Text("Lampirkan File/Video"),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: purple),
                onPressed: () async {
                  if (contentCtrl.text.isEmpty && pickedFile == null) return;
                  Navigator.pop(ctx);
                  setState(() => _isUploading = true);
                  String? supabaseUrl;
                  if (pickedFile != null) {
                    final String safeName = pickedFile!.name.replaceAll(' ', '_');
                    final String storagePath = 'community/${currentUserId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
                    await Supabase.instance.client.storage.from('Postingan').uploadBinary(storagePath, pickedFile!.bytes!);
                    supabaseUrl = Supabase.instance.client.storage.from('Postingan').getPublicUrl(storagePath);
                  }
                  await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/posts"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({"userId": currentUserId, "content": contentCtrl.text, "link": linkCtrl.text, "fileUrl": supabaseUrl, "fileName": pickedFile?.name}));
                  _refreshData();
                  setState(() => _isUploading = false);
                },
                child: const Text("Posting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _showCommentSheet(Post post) {
    TextEditingController ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Komentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (post.comments.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Belum ada komentar.")),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: ListView(
                shrinkWrap: true,
                children: post.comments.map((c) => ListTile(
                  leading: const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 15)),
                  title: Text(c.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(c.content),
                )).toList(),
              ),
            ),
            Row(children: [
              Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Tulis balasan..."))),
              IconButton(icon: Icon(Icons.send, color: purple), onPressed: () async {
                if(ctrl.text.isEmpty) return;
                await http.post(Uri.parse("${GlobalVar.baseUrl}/api/friends/comment"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"userId": currentUserId, "postId": post.id, "content": ctrl.text}));
                Navigator.pop(context);
                _fetchPosts();
              })
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
      child: Row(children: [
        Icon(icon, color: purple), 
        const SizedBox(width: 10), 
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), 
        Text(badge, style: TextStyle(color: purple, fontWeight: FontWeight.bold))
      ])
    );
  }

  Widget _buildUploadProgress() {
    return Container(margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: softPurple, borderRadius: BorderRadius.circular(15)), child: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 15), const Text("Sedang membagikan...")]));
  }

  String _formatTime(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays} hari lalu';
    if (duration.inHours > 0) return '${duration.inHours} jam lalu';
    return '${duration.inMinutes} menit lalu';
  }
}

// === WIDGET: INLINE VIDEO PLAYER ===
class InlineVideoPlayer extends StatefulWidget {
  final String url;
  const InlineVideoPlayer({super.key, required this.url});
  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}
class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) => setState(() {}));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(alignment: Alignment.center, children: [
            AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
            IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 50, color: Colors.white), onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()))
          ])
        : const Center(child: CircularProgressIndicator());
  }
}