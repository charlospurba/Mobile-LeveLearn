import 'dart:io';
import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/user.dart';
import 'package:app/model/trade.dart'; // Import TradeModel
import 'package:app/model/user_trade.dart';
import 'package:app/service/trade_service.dart'; // Import TradeService
import 'package:app/view/main_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../service/user_service.dart';
import '../utils/colors.dart';

class UpdateProfile extends StatefulWidget {
  final Student user;
  // HAPUS availableAvatars statis
  const UpdateProfile({super.key, required this.user});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  Student? user;
  late SharedPreferences prefs;
  PlatformFile? photo;
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  
  String? selectedAvatarUrl;
  List<TradeModel> myOwnedAvatars = []; // Ganti ke TradeModel
  bool isLoadingAvatars = true;
  String userType = "Disruptors"; 

  @override
  void initState() {
    user = widget.user;
    nameController.text = user?.name ?? '';
    usernameController.text = user?.username ?? '';
    selectedAvatarUrl = user?.image;
    _loadData();
    super.initState();
  }

  String formatUrl(String? url) {
    return GlobalVar.formatImageUrl(url);
  }

  void _loadData() async {
    prefs = await SharedPreferences.getInstance();
    try {
      // 1. Fetch User Type
      final adaptiveRes = await http.get(Uri.parse("${GlobalVar.baseUrl}/api/user/adaptive/${widget.user.id}"));
      if (adaptiveRes.statusCode == 200) {
        final data = jsonDecode(adaptiveRes.body);
        if (mounted) setState(() => userType = data['currentCluster'] ?? "Disruptors");
      }

      // 2. FETCH AVATAR DARI TABEL USER_TRADE (DINAMIS)
      final ownedTrades = await TradeService.getUserTrade(widget.user.id);
      final allTrades = await TradeService.getAllTrades();
      
      // Ambil tradeId yang dimiliki user
      final ownedIds = ownedTrades.map((ut) => ut.tradeId).toSet();
      
      if (mounted) {
        setState(() {
          // Filter hanya kategori AVATAR yang sudah dimiliki user
          myOwnedAvatars = allTrades.where((t) => 
            ownedIds.contains(t.id) && t.category == "AVATAR"
          ).toList();
          isLoadingAvatars = false;
        });
      }
    } catch (e) {
      debugPrint("Sync Error Update Profile: $e");
      if(mounted) setState(() => isLoadingAvatars = false);
    }
  }

  Future<void> _showAvatarSelectionDialog(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: MediaQuery.of(context).size.height * 0.6, 
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Text('My Avatar Collection', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
            const Text('Beli avatar baru di menu Trade Center', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            Expanded(
              child: isLoadingAvatars 
                ? const Center(child: CircularProgressIndicator())
                : _buildAvatarGrid(myOwnedAvatars),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarGrid(List<TradeModel> items) {
    if (items.isEmpty) return const Center(child: Text("Belum memiliki koleksi avatar.", style: TextStyle(fontFamily: 'DIN_Next_Rounded')));
    
    return GridView.builder(
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final avatar = items[index];
        final isSelected = selectedAvatarUrl == avatar.image;

        return GestureDetector(
          onTap: () {
            setState(() { 
              selectedAvatarUrl = avatar.image; 
              photo = null; 
            });
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? AppColors.primaryColor : Colors.grey.shade300, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: avatar.image.startsWith('http') 
                ? Image.network(GlobalVar.formatImageUrl(avatar.image), fit: BoxFit.cover)
                : Image.asset('lib/assets/avatars/${avatar.image.split('.').first}.jpeg', 
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Image.asset(avatar.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.person)),
                  ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor, 
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Update Profile", style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded'))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(children: [
              SizedBox(width: 120, height: 120, child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: photo != null 
                  ? (kIsWeb ? Image.memory(photo!.bytes!, fit: BoxFit.cover) : Image.file(File(photo!.path!), fit: BoxFit.cover))
                  : (selectedAvatarUrl != null 
                      ? (selectedAvatarUrl!.startsWith('lib/assets/') 
                          ? Image.asset(selectedAvatarUrl!, fit: BoxFit.cover) 
                          : Image.network(formatUrl(selectedAvatarUrl!), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.person, size: 80)))
                      : const Icon(Icons.person, size: 100)),
              )),
              Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: AppColors.secondaryColor, child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _showUpdatePhotoMenu)))
            ]),
          ),
          const SizedBox(height: 50),
          _buildFields(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, shape: const StadiumBorder()),
              onPressed: () async {
                showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
                
                try {
                  if (photo != null) {
                     final comp = await compressImage(photo!);
                     if (comp != null) await uploadPhotoProfile(comp, 'profile_${user!.id}.jpg');
                  }
                  
                  user!.name = nameController.text;
                  user!.username = usernameController.text;
                  user!.image = selectedAvatarUrl;
                  
                  if (passwordController.text.isNotEmpty) {
                    user!.password = passwordController.text;
                  }
                  
                  await UserService.updateUser(user!);
                  
                  if (mounted) {
                    Navigator.pop(context); 
                    _showDialog(context); 
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
            ),
          ),
        ]),
      ),
    );
  }

  void _showUpdatePhotoMenu() {
    if (userType == "Disruptors") {
      _pickFromGallery();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text("Ganti Foto Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'DIN_Next_Rounded')),
              ListTile(leading: const Icon(Icons.image), title: const Text("Upload dari Galeri", style: TextStyle(fontFamily: 'DIN_Next_Rounded')), onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              }),
              ListTile(leading: const Icon(Icons.face_retouching_natural), title: const Text("Koleksi Avatar (Beli di Trade)", style: TextStyle(fontFamily: 'DIN_Next_Rounded')), onTap: () {
                Navigator.pop(context);
                _showAvatarSelectionDialog(context);
              }),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      setState(() { 
        photo = res.files.first; 
        selectedAvatarUrl = null; 
      });
    }
  }

  Widget _buildFields() {
    return Column(children: [
      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
      const SizedBox(height: 15),
      TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: "Username", labelStyle: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
      const SizedBox(height: 15),
      TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password (Kosongkan jika tidak ganti)", labelStyle: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
    ]);
  }

  Future<void> uploadPhotoProfile(XFile file, String filename) async {
    try {
      final storagePath = 'profile/$filename';
      final fileBytes = await file.readAsBytes();
      await Supabase.instance.client.storage.from('images').uploadBinary(storagePath, fileBytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      selectedAvatarUrl = Supabase.instance.client.storage.from('images').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  Future<XFile?> compressImage(PlatformFile file) async {
    if (kIsWeb) return XFile.fromData(file.bytes!);
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, "compressed_${file.name}");
    return await FlutterImageCompress.compressAndGetFile(file.path!, targetPath, quality: 50).then((f) => f != null ? XFile(f.path) : null);
  }

  void _showDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Success"), content: const Text("Profile Updated."), 
      actions: [TextButton(onPressed: () { Navigator.popUntil(context, (r) => r.isFirst); Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const Mainscreen(navIndex: 4))); }, child: const Text("OK"))]
    ));
  }
}