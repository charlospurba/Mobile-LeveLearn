import 'dart:io';
import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/user.dart';
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

import 'package:app/view/profile_screen.dart';
import '../service/user_service.dart';
import '../utils/colors.dart';

class UpdateProfile extends StatefulWidget {
  final Student user;
  final List<AvatarModel> availableAvatars;

  const UpdateProfile({super.key, required this.user, required this.availableAvatars});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> with SingleTickerProviderStateMixin {
  Student? user;
  late SharedPreferences prefs;
  PlatformFile? photo;
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  
  String? selectedAvatarUrl;
  Set<int> purchasedAvatarIds = {}; 
  late TabController _tabController;
  String userType = "Disruptors"; 

  @override
  void initState() {
    user = widget.user;
    nameController.text = user?.name ?? '';
    usernameController.text = user?.username ?? '';
    selectedAvatarUrl = user?.image;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    super.initState();
  }

  // Helper URL yang merujuk ke GlobalVar
  String formatUrl(String? url) {
    return GlobalVar.formatImageUrl(url);
  }

  void _loadData() async {
    prefs = await SharedPreferences.getInstance();
    try {
      // Sinkronisasi Cluster User (Achievers/Disruptors/etc)
      final response = await http.get(Uri.parse("${GlobalVar.baseUrl}/api/user/adaptive/${widget.user.id}"))
          .timeout(const Duration(seconds: 15));
          
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => userType = data['currentCluster'] ?? "Disruptors");
      }

      // Ambil data ID avatar yang sudah dibeli
      List<int> dbAvatars = await UserService.getPurchasedAvatarsFromDb(widget.user.id);
      if (mounted) {
        setState(() {
          purchasedAvatarIds = dbAvatars.toSet();
          purchasedAvatarIds.add(1); // ID 1 adalah default
        });
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  int getAvatarPrice(int id) {
    if (id <= 1) return 0;
    if (id <= 4) return 100; 
    if (id <= 6) return 200; 
    if (id <= 8) return 250; 
    if (id <= 10) return 300; 
    return 350; 
  }

  Future<void> _showAvatarSelectionDialog(BuildContext context) {
    final myOwnedAvatars = widget.availableAvatars.where((a) => purchasedAvatarIds.contains(a.id)).toList();
    final shopAvatars = widget.availableAvatars.where((a) => !purchasedAvatarIds.contains(a.id)).toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: MediaQuery.of(context).size.height * 0.8, 
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text('Avatar Gallery', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
              const SizedBox(height: 10),
              TabBar(
                controller: _tabController, 
                indicatorColor: AppColors.primaryColor, 
                labelColor: AppColors.primaryColor, 
                tabs: const [Tab(text: 'My Avatars'), Tab(text: 'Shop New')]
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController, 
                  children: [
                    _buildAvatarGrid(myOwnedAvatars, isShop: false), 
                    _buildAvatarGrid(shopAvatars, isShop: true),    
                  ]
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarGrid(List<AvatarModel> items, {required bool isShop}) {
    if (items.isEmpty) return Center(child: Text(isShop ? "Semua avatar telah dibeli!" : "Belum ada avatar.", style: const TextStyle(fontFamily: 'DIN_Next_Rounded')));
    return GridView.builder(
      padding: const EdgeInsets.only(top: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final avatar = items[index];
        final price = getAvatarPrice(avatar.id);
        final isSelected = selectedAvatarUrl == avatar.imageUrl;

        return GestureDetector(
          onTap: () async {
            if (!isShop) {
              setState(() { selectedAvatarUrl = avatar.imageUrl; photo = null; });
              Navigator.pop(context);
            } else {
              _processPurchase(avatar, price);
            }
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? AppColors.primaryColor : (isShop ? Colors.grey.shade300 : Colors.green), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(avatar.imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(isShop ? "$price Pts" : "Owned", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isShop ? Colors.black87 : Colors.green, fontFamily: 'DIN_Next_Rounded')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPurchase(AvatarModel avatar, int price) async {
    int currentPoints = user?.points ?? 0;
    if (currentPoints < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poin tidak mencukupi.')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Konfirmasi', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
        content: Text('Beli avatar seharga $price poin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Beli', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      bool success = await UserService.savePurchasedAvatarToDb(user!.id, avatar.id);
      
      if (mounted) Navigator.pop(context); 

      if (success) {
        setState(() {
          user!.points = currentPoints - price;
          user!.image = avatar.imageUrl;
          purchasedAvatarIds.add(avatar.id);
          selectedAvatarUrl = avatar.imageUrl;
        });
        await UserService.updateUser(user!); 
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar berhasil dibeli!')));
           Navigator.pop(context); // Tutup gallery
        }
      }
    }
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
                
                if (photo != null) {
                   final comp = await compressImage(photo!);
                   if (comp != null) await uploadPhotoProfile(comp, 'profile_${user!.id}.jpg');
                }
                
                user!.name = nameController.text;
                user!.username = usernameController.text;
                user!.image = selectedAvatarUrl;
                if (passwordController.text.isNotEmpty) user!.password = passwordController.text;
                
                await UserService.updateUser(user!);
                if (mounted) {
                  Navigator.pop(context); 
                  _showDialog(context);
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
              ListTile(leading: const Icon(Icons.face_retouching_natural), title: const Text("Gallery Avatar", style: TextStyle(fontFamily: 'DIN_Next_Rounded')), onTap: () {
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

      await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(
            storagePath, 
            fileBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ), 
          );

      selectedAvatarUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(storagePath);
          
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
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
      title: const Text("Success", style: TextStyle(fontFamily: 'DIN_Next_Rounded')), 
      content: const Text("Profile Updated.", style: TextStyle(fontFamily: 'DIN_Next_Rounded')), 
      actions: [
        TextButton(onPressed: () { 
          Navigator.popUntil(context, (r) => r.isFirst); 
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const Mainscreen(navIndex: 4))); 
        }, child: const Text("OK"))
      ]
    ));
  }
}