import 'package:app/service/course_service.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/course_initial_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/course.dart';
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
  bool isLoading = true;

  // Mengambil IP dan Default Image dari GlobalVar agar terpusat
  final String serverIp = GlobalVar.serverIp;
  final String defaultImageUrl = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

  @override
  void initState() {
    super.initState();
    getEnrolledCourse();
    
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });

    _searchController.addListener(_filterCourses);
  }

  // Fungsi helper untuk memperbaiki URL gambar (Sinkron dengan GlobalVar)
  String formatUrl(String? url) {
    return GlobalVar.formatImageUrl(url);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> getEnrolledCourse() async {
    try {
      if (mounted) setState(() => isLoading = true);
      
      pref = await SharedPreferences.getInstance();
      int? id = pref.getInt('userId');
      if (id == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final result = await CourseService.getEnrolledCourse(id);
      
      if (mounted) {
        setState(() {
          allCourses = result;
          filteredCourses = result;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching courses: $e");
      if (mounted) setState(() => isLoading = false);
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
      return 'Progressmu baru $progress%, yuk ditingkatkan!';
    } else if (progress <= 60) {
      return 'Sudah $progress%, jangan patah semangat, ayo!';
    } else if (progress <= 80) {
      return 'Sudah $progress%, lumayan, sedikit lagi!';
    } else {
      return 'Sudah $progress%, tanggung, ayo selesaikan!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // Background Pattern
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage("lib/assets/learnbg.png"),
                fit: BoxFit.cover,
                opacity: 0.1, // Disesuaikan agar teks lebih terbaca
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
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              title: Column(
                children: [
                  const Text(
                    'My Enrolled Courses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'DIN_Next_Rounded',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearch(),
                ],
              ),
            ),
            body: isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : RefreshIndicator(
                    onRefresh: getEnrolledCourse,
                    child: _listCourse(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
        decoration: InputDecoration(
          hintText: _isFocused ? "" : 'Cari kursus Anda...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _listCourse() {
    if (filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset('lib/assets/pictures/background-pattern.png', width: 150),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kursus tidak ditemukan',
              style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        return _buildCourseItem(filteredCourses[index]);
      },
    );
  }

  Widget _buildCourseItem(Course course) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: AppColors.primaryColor,
          child: InkWell(
            onTap: () async {
              await pref.setInt('lastestSelectedCourse', course.id);
              if (!mounted) return;
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CourseInitialScreen(id: course.id))
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image(
                      image: courseImage,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          course.codeCourse.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'DIN_Next_Rounded',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        course.description ?? "No description available",
                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'DIN_Next_Rounded'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 15),
                      // Progress Bar Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progress', style: TextStyle(color: Colors.white, fontSize: 12)),
                          Text('${course.progress ?? 0}%', style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                          value: (course.progress ?? 0) / 100,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        progressSentence(course.progress ?? 0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white60,
                          fontFamily: 'DIN_Next_Rounded',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}