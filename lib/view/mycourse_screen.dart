import 'package:app/service/course_service.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/course_initial_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/course.dart';

// Import GlobalVar jika Anda meletakkan fungsi formatUrl di sana, 
// atau gunakan variabel lokal seperti di bawah ini.
import 'package:app/global_var.dart';

class MycourseScreen extends StatefulWidget {
  const MycourseScreen({super.key});

  @override
  State<MycourseScreen> createState() => _CourseDetail();
}

class _CourseDetail extends State<MycourseScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isFocused = false;
  late SharedPreferences pref;
  List<Course> allCourses = [];
  List<Course> filteredCourses = [];
  
  // Konfigurasi IP untuk akses gambar dari server lokal
  final String serverIp = "10.106.207.43";
  final String defaultImageUrl = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

  @override
  void initState() {
    super.initState();
    getEnrolledCourse();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    _searchController.addListener(_filterCourses);
  }

  // Fungsi helper untuk memperbaiki URL gambar agar muncul di HP
  String formatUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('lib/assets/')) return url;
    if (url.contains('localhost')) return url.replaceAll('localhost', serverIp);
    if (!url.startsWith('http')) return 'http://$serverIp:7000$url';
    return url;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void getEnrolledCourse() async {
    try {
      pref = await SharedPreferences.getInstance();
      int? id = pref.getInt('userId');
      if (id == null) return;

      final result = await CourseService.getEnrolledCourse(id);
      if (!mounted) return;

      setState(() {
        allCourses = result;
        filteredCourses = result;
      });
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    }
  }

  void _filterCourses() {
    String query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        filteredCourses = List.from(allCourses);
      });
      return;
    }

    List<Course> newFilteredList = allCourses.where((c) {
      return c.courseName.toLowerCase().contains(query) ||
          c.codeCourse.toLowerCase().contains(query);
    }).toList();

    setState(() {
      filteredCourses = newFilteredList;
    });
  }

  String progressSentence(int progress) {
    if (progress <= 20) {
      return 'Progressmu baru $progress%, ayo kerjakan lagi!';
    } else if (progress <= 40) {
      return 'Progressmu baru $progress%, sudah ada progressmu, yuk kerjakan!';
    } else if (progress <= 60) {
      return 'Progressmu baru $progress%, jangan patah semangat, ayo!';
    } else if (progress <= 80) {
      return 'Progressmu sudah $progress%, lumayan, semangat mengerjakannya!';
    } else {
      return 'Progressmu sudah $progress%, tanggung, ayo kerjakan sedikit lagi, semangat!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage("lib/assets/learnbg.png"),
                fit: BoxFit.cover,
                opacity: 0.7
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              toolbarHeight: 180,
              backgroundColor: AppColors.primaryColor,
              automaticallyImplyLeading: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(child: Text('Enrolled Course', style: TextStyle(fontSize: 24, color: Colors.white, fontFamily: 'DIN_Next_Rounded',),),),
                    ),
                    _buildSearch(),
                  ],
                ),
              ),
            ),
            body: _listCourse(),
          ),
        ],
      )
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: _isFocused ? "" : 'Mau belajar apa hari ini?',
        hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'DIN_Next_Rounded',),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _listCourse() {
    return filteredCourses.isEmpty
    ? Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover),
        ),
        child: const Center(child: Text('Kamu belum terdaftar di course apapun', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
      )
    : ListView.builder(
      itemCount: filteredCourses.length,
      itemBuilder: (context, count) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 1.0),
          child: _buildCourseItem(filteredCourses[count]),
        );
      },
    );
  }

  Widget _buildCourseItem(Course course) {
    // Menentukan sumber gambar (Asset vs Network)
    ImageProvider courseImage;
    String formattedUrl = formatUrl(course.image);

    if (course.image != null && course.image.isNotEmpty) {
      if (course.image.startsWith('lib/assets/')) {
        courseImage = AssetImage(course.image);
      } else {
        courseImage = NetworkImage(formattedUrl);
      }
    } else {
      courseImage = NetworkImage(defaultImageUrl);
    }

    return GestureDetector(
      onTap: () async {
        await pref.setInt('lastestSelectedCourse', course.id);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => CourseInitialScreen(id: course.id)));
      },
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        color: AppColors.primaryColor,
        elevation: 5,
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            // PERBAIKAN TAMPILAN GAMBAR
            Image(
              image: courseImage,
              height: 140, // Sedikit lebih tinggi agar proporsional
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'lib/assets/pictures/imk-picture.jpg', 
                  height: 140, 
                  width: double.infinity, 
                  fit: BoxFit.cover
                );
              },
            ),
            ListTile(
              title: Text(course.codeCourse.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.accentColor, fontFamily: 'DIN_Next_Rounded'),),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white, fontFamily: 'DIN_Next_Rounded',),),
                  Text(course.description ?? "", style: const TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'DIN_Next_Rounded',), maxLines: 2, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 10,),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                      value: (course.progress ?? 0) / 100,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Text(progressSentence(course.progress ?? 0), style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white, fontFamily: 'DIN_Next_Rounded',),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}