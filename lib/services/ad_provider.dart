
import 'package:adbeaver/model/ad_data.dart';
import 'package:flutter/cupertino.dart';

class AdCreationProvider with ChangeNotifier{
  final AdCreationData _formData = AdCreationData();
  AdCreationData get formData => _formData;

  void setCategory(String category) {
   _formData.category = category;
   notifyListeners();
  }
  void setAdName(String name){
    _formData.adname = name;
    notifyListeners();
  }
  void setImageUrl(String imageurl){
    _formData.image_url = imageurl;
    notifyListeners();
  }

  void setAdMethod(String method){
    _formData.admethod = method;
    notifyListeners();
  }

  void setCost(int cost){
    _formData.cost = cost;
    notifyListeners();
  }

  void setStartDate(DateTime? startdate) {
    _formData.startdate = startdate;
    notifyListeners();
  }
  void setTargetGender(List<String> gender){
    _formData.target_gender = List<String>.from(gender);
    notifyListeners();
  }

  void setTargetAges(String ageLabel){
    if(_formData.target_ages.contains(ageLabel)){
      _formData.target_ages?.remove(ageLabel);
    }
    else{
      _formData.target_ages?.add(ageLabel);
    }
    notifyListeners();
  }
  void setStates(String state){
    _formData.adstate= state;
    notifyListeners();
  }
  void setStartOption(String option) {
     formData.startOption = option;
     notifyListeners();
  }
  void resetForm() {
      _formData.category = null;
      _formData.adname = null;
      _formData.image_url = null;
      _formData.admethod = null;
      _formData.cost = 0;
      _formData.startdate = null;
      _formData.target_gender = [];
      _formData.target_ages = [];
      _formData.adstate = null;
      notifyListeners();
  }
}
