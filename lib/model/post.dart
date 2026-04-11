// class PostModel {
//   final int id;
//   final String userName;
//   final String? userImage;
//   final String? content;
//   final String? link;
//   final String? fileUrl;
//   final String? fileName;
//   final DateTime createdAt;

//   PostModel({
//     required this.id,
//     required this.userName,
//     this.userImage,
//     this.content,
//     this.link,
//     this.fileUrl,
//     this.fileName,
//     required this.createdAt,
//   });

//   factory PostModel.fromJson(Map<String, dynamic> json) {
//     // PROTEKSI: Ambil object user secara aman
//     final userData = json['user'] as Map<String, dynamic>?;

//     return PostModel(
//       id: json['id'] ?? 0,
//       userName: userData != null ? (userData['name'] ?? 'User') : 'Anonymous',
//       userImage: userData != null ? userData['image'] : null,
//       content: json['content'],
//       link: json['link'],
//       fileUrl: json['fileUrl'],
//       fileName: json['fileName'],
//       createdAt: json['createdAt'] != null 
//           ? DateTime.parse(json['createdAt']) 
//           : DateTime.now(),
//     );
//   }
// }