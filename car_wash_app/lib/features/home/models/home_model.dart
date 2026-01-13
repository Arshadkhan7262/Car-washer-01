/// Home Model
/// Add your data models here
class HomeModel {
  final String? message;
  
  HomeModel({
    this.message,
  });
  
  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      message: json['message'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}

