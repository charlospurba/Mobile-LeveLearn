class MyCourse {
  String _imageUrl;
  String _surnameCourse;
  String _courseName;
  String _description;
  int _progress;

  MyCourse (this._imageUrl, this._surnameCourse, this._courseName, this._description, this._progress);

  String getImageUrl(){
    return _imageUrl;
  }

  String getSurnameCourse() {
    return _surnameCourse;
  }

  String getCourseName() {
    return _courseName;
  }

  String getDescription() {
    return _description;
  }

  int getProgress() {
    return _progress;
  }

  void setImageUrl(String url) {
    _imageUrl = url;
  }

  void setSurnameCourse(String surnameCourse) {
    _surnameCourse = surnameCourse.toUpperCase();
  }

  void setCourseName(String course){
    _courseName = course;
  }

  void setDescription(String desc) {
    _description = desc;
  }

  void setProgress(int progress) {
    _progress = progress;
  }
}