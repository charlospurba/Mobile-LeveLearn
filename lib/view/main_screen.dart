import 'package:app/view/course_detail_screen.dart';
import 'package:app/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'friends_screen.dart';
import 'home_screen.dart';
import 'mycourse_screen.dart';

Color purple = Color(0xFF441F7F);
Color backgroundNavHex = Color(0xFFF3EDF7);
const url = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

class Mainscreen extends StatefulWidget {
  final int navIndex;
  const Mainscreen({super.key, this.navIndex = 0});

  @override
  State<Mainscreen> createState() => _MainState();
}

class _MainState extends State<Mainscreen> {
  late SharedPreferences pref;
  int idCourse = 0;
  int navIndex = 0;

  void getCourseDetail() async {
    int storedId = pref.getInt('getCourseDetail') ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        idCourse = storedId;
      });
    });
  }

  @override
  void initState() {
    navIndex = widget.navIndex;
    _initPreferences();
    super.initState();
  }

  void _initPreferences() async {
    pref = await SharedPreferences.getInstance();
    if (mounted) {
      getCourseDetail();
    }
  }


  void updateIndex(int index) {
    setState(() {
      navIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return Homescreen(updateIndex: updateIndex,);
      case 1:
        return MycourseScreen();
      case 2:
        return CourseDetailScreen(id: idCourse);
      case 3:
        return FriendsScreen();
      case 4:
        return ProfileScreen();
      default:
        return Homescreen(updateIndex: updateIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(navIndex),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          onTap: (index){
            setState(() {
              navIndex = index;
            });
          },
          currentIndex: navIndex,
          selectedLabelStyle: TextStyle(
              fontFamily:
              'DIN_Next_Rounded',
              fontWeight: FontWeight.bold
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily:
            'DIN_Next_Rounded',
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LineAwesomeIcons.building),
              label: 'Home',
            ),
            BottomNavigationBarItem(
                icon: Icon(LineAwesomeIcons.search_solid),
                label: 'Search',
                backgroundColor: Colors.black
            ),
            BottomNavigationBarItem(
                icon: Icon(LineAwesomeIcons.project_diagram_solid),
                label: 'Course',
                backgroundColor: Colors.black
            ),
            BottomNavigationBarItem(
                icon: Icon(LineAwesomeIcons.user_friends_solid),
                label: 'Friends',
                backgroundColor: Colors.black
            ),
            BottomNavigationBarItem(
                icon: Icon(LineAwesomeIcons.person_booth_solid),
                label: 'Profile',
                backgroundColor: Colors.black
            )
          ]
      ),
    );
  }

}