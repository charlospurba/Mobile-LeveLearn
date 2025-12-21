import 'dart:io';
import 'package:app/model/user.dart';
import 'package:app/view/main_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  bool hasChanges = false;
  bool passwordHasChanges = false;

  String? selectedAvatarUrl;
  Set<int> purchasedAvatarIds = {}; 
  late TabController _tabController;

  @override
  void initState() {
    user = widget.user;
    nameController.text = user?.name ?? '';
    usernameController.text = user?.username ?? '';
    selectedAvatarUrl = user?.image;
    _loadData();
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  void _loadData() async {
    prefs = await SharedPreferences.getInstance();
    try {
      List<int> dbAvatars = await UserService.getPurchasedAvatarsFromDb(widget.user.id);
      setState(() {
        purchasedAvatarIds = dbAvatars.toSet();
        purchasedAvatarIds.add(1); 
      });
      await prefs.setStringList('purchasedAvatars', purchasedAvatarIds.map((e) => e.toString()).toList());
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Text('Shop Avatar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TabBar(controller: _tabController, indicatorColor: AppColors.primaryColor, labelColor: AppColors.primaryColor, tabs: const [Tab(text: 'Avatar'), Tab(text: 'Gift')]),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  GridView.builder(
                    padding: const EdgeInsets.only(top: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
                    itemCount: widget.availableAvatars.length,
                    itemBuilder: (context, index) {
                      final avatar = widget.availableAvatars[index];
                      final price = getAvatarPrice(avatar.id);
                      final isPurchased = purchasedAvatarIds.contains(avatar.id);
                      final isSelected = selectedAvatarUrl == avatar.imageUrl;

                      return GestureDetector(
                        onTap: () async {
                          if (isPurchased) {
                            setState(() { selectedAvatarUrl = avatar.imageUrl; photo = null; hasChanges = true; });
                            Navigator.pop(context);
                          } else {
                            int currentPoints = user?.points ?? 0;
                            if (currentPoints >= price) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Konfirmasi Pembelian'),
                                  content: Text('Beli avatar ini seharga $price poin?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Beli')),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                // Tampilkan Loading
                                showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
                                
                                // 1. Kirim Transaksi ke Backend
                                bool successPurchase = await UserService.savePurchasedAvatarToDb(user!.id, avatar.id);
                                
                                if (mounted) Navigator.pop(context); // Tutup Loading

                                if (successPurchase) {
                                  // 2. Jika sukses di server, update poin di objek user lokal
                                  setState(() {
                                    user!.points = currentPoints - price;
                                    user!.image = avatar.imageUrl;
                                    purchasedAvatarIds.add(avatar.id);
                                    selectedAvatarUrl = avatar.imageUrl;
                                    photo = null;
                                    hasChanges = true;
                                  });
                                  
                                  // 3. Simpan perubahan profil & poin ke database utama user
                                  await UserService.updateUser(user!); 
                                  await prefs.setStringList('purchasedAvatars', purchasedAvatarIds.map((e) => e.toString()).toList());
                                  
                                  if (context.mounted) Navigator.pop(context); // Tutup Shop modal
                                } else {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghubungkan ke server. Pastikan data master avatar tersedia.')));
                                }
                              }
                            } else {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poin tidak mencukupi.')));
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: isSelected ? AppColors.primaryColor : (isPurchased ? Colors.green : Colors.grey.shade300), width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(avatar.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(isPurchased ? "Milikmu" : "$price Poin", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                  const Center(child: Text("Segera Hadir")),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor, title: const Text("Update Profile", style: TextStyle(color: Colors.white))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(children: [
              SizedBox(width: 120, height: 120, child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: photo != null ? (kIsWeb ? Image.memory(photo!.bytes!, fit: BoxFit.cover) : Image.file(File(photo!.path!), fit: BoxFit.cover))
                : (selectedAvatarUrl != null ? (selectedAvatarUrl!.startsWith('lib/assets/') ? Image.asset(selectedAvatarUrl!, fit: BoxFit.cover) : Image.network(selectedAvatarUrl!, fit: BoxFit.cover))
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
                if (photo != null) {
                   final comp = await compressImage(photo!);
                   if (comp != null) await uploadPhotoProfile(comp, 'profile_${user!.id}.jpg');
                }
                user!.name = nameController.text;
                user!.username = usernameController.text;
                user!.image = selectedAvatarUrl;
                if (passwordController.text.isNotEmpty) user!.password = passwordController.text;

                await UserService.updateUser(user!);
                if (mounted) _showDialog(context);
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showUpdatePhotoMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text("Ganti Foto Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ListTile(leading: const Icon(Icons.image), title: const Text("Upload dari Galeri"), onTap: () async {
            final res = await FilePicker.platform.pickFiles(type: FileType.image);
            if (res != null) {
              setState(() { photo = res.files.first; selectedAvatarUrl = null; hasChanges = true; });
              Navigator.pop(context);
            }
          }),
          ListTile(leading: const Icon(Icons.face_retouching_natural), title: const Text("Pilih dari Avatar Shop"), onTap: () {
            Navigator.pop(context);
            _showAvatarSelectionDialog(context);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(children: [
      TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
      const SizedBox(height: 15),
      TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
      const SizedBox(height: 15),
      TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password (Biarkan kosong jika tidak ganti)")),
    ]);
  }

  Future<void> uploadPhotoProfile(XFile file, String filename) async {
    try {
      final storagePath = 'profile/$filename';
      await Supabase.instance.client.storage.from('images').uploadBinary(storagePath, await file.readAsBytes());
      selectedAvatarUrl = Supabase.instance.client.storage.from('images').getPublicUrl(storagePath);
      setState(() { hasChanges = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Gagal: $e')));
    }
  }

  Future<XFile?> compressImage(PlatformFile file) async {
    if (kIsWeb) return XFile.fromData(file.bytes!);
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, "compressed_${file.name}");
    return await FlutterImageCompress.compressAndGetFile(file.path!, targetPath, quality: 50).then((f) => f != null ? XFile(f.path) : null);
  }

  void _showDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Success"), content: const Text("Profile Updated."), actions: [
      TextButton(onPressed: () { Navigator.popUntil(context, (r) => r.isFirst); Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => Mainscreen(navIndex: 4))); }, child: const Text("OK"))
    ]));
  }
}