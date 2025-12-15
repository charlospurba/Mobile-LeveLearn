// import 'package:flutter/material.dart';
// import '../model/course.dart';
// import 'courseDetailScreen.dart';
//
// Color purple = Color(0xFF441F7F);
// Color backgroundNavHex = Color(0xFFF3EDF7);
// const url = 'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';
//
// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//
//   @override
//   State<SearchScreen> createState() => _SearchState();
// }
//
// class _SearchState extends State<SearchScreen> {
//   final FocusNode _focusNode = FocusNode();
//   final TextEditingController _searchController = TextEditingController();
//   bool _isFocused = false;
//
//   // List of all courses
//   List<Course> allCourses = Course.getAllCourses();
//
//   // List of courses filtered based on search input
//   List<Course> filteredCourses = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _focusNode.addListener(() {
//       setState(() {
//         _isFocused = _focusNode.hasFocus;
//       });
//     });
//
//     _searchController.addListener(_filterCourses);
//     filteredCourses = List.from(allCourses); // Initially show all courses
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterCourses() {
//     String query = _searchController.text.toLowerCase().trim();
//     if (query.isEmpty) {
//       setState(() {
//         filteredCourses = List.from(allCourses); // Reset list if empty
//       });
//       return;
//     }
//
//     List<Course> newFilteredList = allCourses.where((c) {
//       return c.getSurnameCourse().toLowerCase().contains(query) ||
//           c.getCourseName().toLowerCase().contains(query);
//     }).toList();
//
//     setState(() {
//       filteredCourses = newFilteredList; // Ensures UI updates immediately
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           toolbarHeight: 100,
//           backgroundColor: purple,
//           automaticallyImplyLeading: false,
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(15),
//               bottomRight: Radius.circular(15),
//             ),
//           ),
//           title: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildSearch(),
//               ],
//             ),
//           ),
//         ),
//         body: _listCourse(),
//       ),
//     );
//   }
//
//   Widget _buildSearch() {
//     return TextField(
//       controller: _searchController,
//       focusNode: _focusNode,
//       decoration: InputDecoration(
//         hintText: _isFocused ? "" : 'Mau belajar apa hari ini?',
//         hintStyle: TextStyle(color: Colors.grey),
//         prefixIcon: Icon(Icons.search, color: Colors.grey),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//     );
//   }
//
//   Widget _listCourse() {
//     return ListView.builder(
//       itemCount: filteredCourses.length,
//       itemBuilder: (context, count) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 1.0),
//           child: _buildCourseItem(filteredCourses[count]),
//         );
//       },
//     );
//   }
//
//   Widget _buildCourseItem(Course course) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CourseDetailScreen(course: course),
//           ),
//         );
//       },
//       child: Card(
//         clipBehavior: Clip.antiAliasWithSaveLayer,
//         semanticContainer: true,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//         color: Colors.deepPurple[500],
//         elevation: 5,
//         margin: EdgeInsets.all(10),
//         child:  Column(
//           children: [
//             Image.network(url, height: 100, width: double.infinity, fit: BoxFit.cover),
//             ListTile(
//               title: Text(course.getSurnameCourse().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey.shade300),),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(course.getCourseName(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),),
//                   Text(course.getDescription(), style: TextStyle(fontSize: 13, color: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis)
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
