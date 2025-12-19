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
import 'package:intl/intl.dart';

// [FIX] Import AvatarModel dari profile_screen.dart
import 'package:app/view/profile_screen.dart';

import '../service/user_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

class UpdateProfile extends StatefulWidget {
  final Student user;
  // [BARU & FIX] Tambahkan parameter availableAvatars
  final List<AvatarModel> availableAvatars;

  const UpdateProfile({
    super.key,
    required this.user,
    required this.availableAvatars, // Wajibkan parameter ini
  });

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile>
    with SingleTickerProviderStateMixin {
  Student? user;
  late SharedPreferences prefs;
  PlatformFile? photo;
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool hasChanges = false;
  bool passwordHasChanges = false;
  FilePickerResult? result;

  // [BARU] State Avatar
  String? selectedAvatarUrl;
  Set<int> purchasedAvatarIds = {}; // Mock data pembelian
  late TabController _tabController;

  @override
  void initState() {
    user = widget.user;
    // Set initial values
    nameController.text = user?.name ?? '';
    usernameController.text = user?.username ?? '';
    selectedAvatarUrl = user?.image; // Inisialisasi dengan gambar user saat ini

    _loadPreferences();
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // Muat preferensi dan ID avatar yang sudah dibeli
  void _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();

    // Muat ID avatar yang sudah dibeli (mocking purchased state)
    final purchasedString = prefs.getStringList('purchasedAvatars') ?? [];
    setState(() {
      purchasedAvatarIds = purchasedString.map(int.parse).toSet();
      // Pastikan avatar default (id 1, price 0) selalu dianggap sudah dibeli
      purchasedAvatarIds.add(1);
    });
  }

  // Simpan ID avatar yang sudah dibeli
  Future<void> _savePurchasedAvatars() async {
    final purchasedList =
        purchasedAvatarIds.map((id) => id.toString()).toList();
    await prefs.setStringList('purchasedAvatars', purchasedList);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> uploadPhotoProfile(XFile file, String filename) async {
    final path = 'profile/$filename';

    Uint8List bytes = await file.readAsBytes();

    try {
      await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(path, bytes);
      final publicUrl = getPublicUrl(path);
      if (kDebugMode) {
        print(publicUrl);
      }
      setState(() {
        selectedAvatarUrl =
            publicUrl; // Update selected URL dengan foto yang baru diupload
      });
      hasChanges = true;
    } catch (e) {
      if (kDebugMode) {
        print('Upload error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupload foto: $e')),
      );
    }
  }

  String getPublicUrl(String filePath) {
    return Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(filePath);
  }

  Future<void> updateUser() async {
    if (user == null) return;

    // Pastikan user.image diupdate dengan selectedAvatarUrl sebelum update
    user!.image = selectedAvatarUrl;

    final result = await UserService.updateUser(user!);
    setState(() {
      user = result;
      // Perbarui poin di shared preferences setelah update berhasil
      if (user != null) {
        prefs.setInt('userPoints', user!.points ?? 0);
      }
    });

    // Perbarui SharedPreferences
    if (user != null) {
      await prefs.setInt('userId', user!.id);
      await prefs.setString('name', user!.name);
      await prefs.setString('role', user!.role);
    }
  }

  Future<void> updateUserPhoto() async {
    // Fungsi ini diasumsikan mengirim URL gambar (user!.image/selectedAvatarUrl) ke backend.
    if (user?.image != null) {
      await UserService.updateUserPhoto(user!);
    }
  }

  Future<void> updatePassword() async {
    await UserService.updatePassword(user!);
  }

  Future<XFile?> compressImage(PlatformFile file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, "compressed_${file.name}");

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.path!,
      targetPath,
      quality: 50,
      format: CompressFormat.jpeg,
    );

    if (compressedFile != null) {
      return XFile(compressedFile.path);
    }
    return null;
  }

  // [BARU] FUNGSI LOGIKA AVATAR
  // Mengembalikan Future<bool?> untuk menandakan apakah ada pemilihan/pembelian yang sukses
  Future<bool?> _showAvatarSelectionDialog(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            // Fungsi Pembelian/Pemilihan Avatar
            void handleAvatarSelection(AvatarModel avatar) async {
              // 1. Jika avatar sudah dibeli atau gratis
              if (purchasedAvatarIds.contains(avatar.id)) {
                setState(() {
                  selectedAvatarUrl = avatar.imageUrl; // Pilih avatar
                  hasChanges = true;
                });
                Navigator.pop(context, true);
                return;
              }

              // 2. Coba beli avatar
              final userPoints = user!.points ?? 0;
              if (userPoints >= avatar.price) {
                // Konfirmasi Pembelian
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Pembelian'),
                    content: Text(
                        'Anda yakin ingin membeli avatar ini seharga ${avatar.price} Poin?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Beli',
                              style: TextStyle(color: AppColors.primaryColor))),
                    ],
                  ),
                );

                if (confirm == true) {
                  // Lakukan Pembelian
                  int newPoints = userPoints - avatar.price;
                  user!.points = newPoints; // [FIX] Pastikan tipe data int
                  purchasedAvatarIds.add(avatar.id);
                  await _savePurchasedAvatars();

                  // Perbarui state lokal & global
                  setState(() {
                    selectedAvatarUrl = avatar.imageUrl; // Pilih avatar
                    hasChanges = true;
                  });

                  // SetState di modal untuk refresh UI pembelian
                  setStateModal(() {});

                  // Kembali ke UpdateProfile
                  Navigator.pop(context, true);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Avatar berhasil dibeli! Sisa Poin: ${user!.points}')),
                  );
                }
              } else {
                // Poin tidak cukup
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Poin tidak cukup untuk membeli avatar ini.')),
                );
              }
            }

            // UI Modal
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Avatar',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DIN_Next_Rounded')),
                    const SizedBox(height: 16),
                    // Tabs Avatar dan Gift (berdasarkan gambar 7edc63.png)
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryColor,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Avatar'),
                        Tab(text: 'Gift'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab Avatar
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: widget.availableAvatars.length,
                            itemBuilder: (context, index) {
                              final avatar = widget.availableAvatars[index];
                              final isPurchased =
                                  purchasedAvatarIds.contains(avatar.id);
                              final isSelected =
                                  selectedAvatarUrl == avatar.imageUrl;

                              return GestureDetector(
                                onTap: () => handleAvatarSelection(avatar),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : (isPurchased
                                              ? Colors.green
                                              : Colors.grey),
                                      width: 3,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          // Menggunakan Image.asset untuk avatar yang merupakan path lokal
                                          child: Image.asset(avatar.imageUrl,
                                              fit: BoxFit.cover, errorBuilder:
                                                  (context, error, stackTrace) {
                                            return const Icon(Icons.error);
                                          }),
                                        ),
                                      ),
                                      // Label Harga / Status
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: isSelected
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  5)),
                                                ),
                                                child: const Icon(Icons.check,
                                                    size: 16,
                                                    color: Colors.white),
                                              )
                                            : isPurchased
                                                ? Container() // Biarkan kosong jika sudah dibeli tapi tidak dipilih
                                                : Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(5)),
                                                    ),
                                                    child: Text(
                                                        '${avatar.price}',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black)),
                                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Tab Gift (Kosong)
                          const Center(
                              child: Text("Fitur Gift Belum Tersedia")),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor),
                        onPressed: () => Navigator.pop(
                            context, false), // Tutup tanpa memilih/membeli
                        child: Text('Tutup',
                            style: TextStyle(
                                fontFamily: 'DIN_Next_Rounded',
                                color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
            onPressed: () {
              // Kembali ke ProfileScreen dengan nilai 'true' jika ada perubahan
              Navigator.pop(context, hasChanges);
            },
            icon: const Icon(LineAwesomeIcons.angle_left_solid,
                color: Colors.white)),
        title: Text("Update Profile",
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                        'lib/assets/pictures/background-pattern.png'),
                    fit: BoxFit.cover)),
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: photo != null
                              ? (photo!.bytes != null
                                  ? Image.memory(photo!.bytes!,
                                      fit: BoxFit.cover)
                                  : Image.file(File(photo!.path!),
                                      fit: BoxFit.cover))
                              : (selectedAvatarUrl != null &&
                                      selectedAvatarUrl!.isNotEmpty
                                  ? Image.network(selectedAvatarUrl!,
                                      fit: BoxFit.cover, errorBuilder:
                                          (context, error, stackTrace) {
                                      // Fallback jika Image.network gagal (mungkin karena URL adalah path lokal avatar)
                                      return Image.asset(selectedAvatarUrl!,
                                          fit: BoxFit.cover, errorBuilder:
                                              (context, error, stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 100, color: Colors.grey);
                                      });
                                    })
                                  : const Icon(Icons.person,
                                      size: 100, color: Colors.grey)),
                        ),
                      ),
                      // GANTI TOMBOL EDIT FOTO DENGAN POPUPMENU PILIHAN AVATAR/UPLOAD
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: AppColors.secondaryColor),
                          child: PopupMenuButton<String>(
                            icon: const Icon(LineAwesomeIcons.camera_solid,
                                color: Colors.white, size: 20),
                            onSelected: (String result) async {
                              if (result == 'upload') {
                                // Logika Upload Foto Manual
                                final pickerResult =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['jpg', 'jpeg', 'png'],
                                );

                                if (pickerResult == null) return;

                                setState(() {
                                  photo = pickerResult.files.first;
                                  selectedAvatarUrl =
                                      null; // Hapus URL avatar jika upload manual
                                  hasChanges = true;
                                });
                              } else if (result == 'avatar') {
                                // Logika Pilih/Beli Avatar
                                final bool? selectionResult =
                                    await _showAvatarSelectionDialog(context);

                                if (selectionResult == true) {
                                  // Jika pemilihan avatar berhasil, set photo=null agar tampil selectedAvatarUrl
                                  setState(() {
                                    photo = null;
                                    hasChanges = true;
                                  });
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'upload',
                                child: Text('Upload Foto'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'avatar',
                                child: Text('Pilih Avatar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Form(
                      child: Column(
                    children: [
                      TextFormField(
                        onChanged: (_) => hasChanges = true,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontFamily: 'DIN_Next_Rounded',
                            ),
                        controller: nameController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                            prefixIconColor: AppColors.primaryColor,
                            floatingLabelStyle:
                                const TextStyle(color: AppColors.primaryColor),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: AppColors.primaryColor),
                            ),
                            label: Text("Name",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontFamily: 'DIN_Next_Rounded',
                                    )),
                            hintText: user?.name != null && user?.name != ''
                                ? user!.name
                                : "Name",
                            prefixIcon:
                                Icon(LineAwesomeIcons.person_booth_solid)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        onChanged: (_) => hasChanges = true,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontFamily: 'DIN_Next_Rounded',
                            ),
                        controller: usernameController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                            prefixIconColor: AppColors.primaryColor,
                            floatingLabelStyle:
                                const TextStyle(color: AppColors.primaryColor),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: AppColors.primaryColor),
                            ),
                            label: Text("Username",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontFamily: 'DIN_Next_Rounded',
                                    )),
                            hintText:
                                user?.username != null && user?.username != ''
                                    ? user!.username
                                    : "Username",
                            prefixIcon: Icon(LineAwesomeIcons.user)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        onChanged: (_) => passwordHasChanges = true,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontFamily: 'DIN_Next_Rounded',
                            ),
                        controller: passwordController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                            prefixIconColor: AppColors.primaryColor,
                            floatingLabelStyle: const TextStyle(
                                color: AppColors.secondaryColor),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: AppColors.primaryColor),
                            ),
                            label: Text("Password",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontFamily: 'DIN_Next_Rounded',
                                    )),
                            prefixIcon:
                                Icon(LineAwesomeIcons.fingerprint_solid)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                            onPressed: () async {
                              // Cek jika ada foto yang diupload secara manual
                              if (photo != null) {
                                final filename =
                                    '${photo?.name.split('.').first}_${user!.studentId}_${DateTime.now().millisecondsSinceEpoch}.${photo?.extension}';
                                final compressedXFile =
                                    await compressImage(photo!);

                                if (compressedXFile != null) {
                                  await uploadPhotoProfile(
                                      compressedXFile, filename);
                                }
                              }
                              String newName = nameController.text.trim();
                              String newUsername =
                                  usernameController.text.trim();
                              String newPassword =
                                  passwordController.text.trim();

                              // Update user data object
                              if (newName.isNotEmpty && newName != user?.name) {
                                user?.name = newName;
                                hasChanges = true;
                              }
                              if (newUsername.isNotEmpty &&
                                  newUsername != user?.username) {
                                user?.username = newUsername;
                                hasChanges = true;
                              }
                              if (newPassword.isNotEmpty &&
                                  newPassword != user?.password) {
                                user?.password = newPassword;
                                hasChanges = true;
                                passwordHasChanges = true;
                              }

                              // Check if image/avatar was changed (baik dari upload manual atau pemilihan avatar)
                              if (selectedAvatarUrl != user?.image) {
                                user?.image = selectedAvatarUrl;
                                hasChanges = true;
                              }

                              if (hasChanges) {
                                if (passwordHasChanges) {
                                  await updatePassword();
                                }
                                // Hanya panggil updateUserPhoto jika ada perubahan foto/avatar
                                if (photo != null ||
                                    user!.image != widget.user.image) {
                                  await updateUserPhoto();
                                }

                                await updateUser();
                                showSuccessDialog(context);
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Tidak ada perubahan untuk disimpan.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                            ),
                            child: Text("Save",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontFamily: 'DIN_Next_Rounded',
                                        color: Colors.white))),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(
                                text: "Joined: ",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black),
                                children: [
                                  TextSpan(
                                      text: DateFormat('dd MMMM yyyy HH:mm:ss')
                                          .format(user!.createdAt),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primaryColor))
                                ],
                              )),
                              Text.rich(TextSpan(
                                text: "Last Modified: ",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black),
                                children: [
                                  TextSpan(
                                      text: DateFormat('dd MMMM yyyy HH:mm:ss')
                                          .format(user!.updatedAt),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primaryColor))
                                ],
                              )),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await prefs.clear();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.1),
                                elevation: 0,
                                foregroundColor: Colors.red,
                                shape: const StadiumBorder(),
                                side: BorderSide.none),
                            child: Text(
                              "Delete",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontFamily: 'DIN_Next_Rounded',
                                      color: Colors.red),
                            ),
                          )
                        ],
                      )
                    ],
                  ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Successful Update"),
          content: const Text("Akunmu sudah diperbaharui"),
          actions: [
            TextButton(
              onPressed: () {
                // Memberi sinyal ke ProfileScreen untuk refresh data dan kembali ke MainScreen index 4 (Profile)
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Mainscreen(navIndex: 4)),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
