class AdCreationData {
  String? category;

  String? adname;
  String? image_url;

  String? admethod;
  int? cost;
  DateTime? startdate;

  List<String> target_gender;
  List<String> target_ages;
  String? adstate;
  String? startOption;

  AdCreationData({
    this.category,
    this.adname,
    this.image_url,
    this.admethod,
    this.cost = 0,
    this.startdate,
    List<String>? target_gender,
    List<String>? target_ages,
    this.adstate,
    this.startOption,
  })  : target_gender = List<String>.from(target_gender ?? const []),
          target_ages   = List<String>.from(target_ages ?? const []);


  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'adname': adname,
      'image_url': image_url,
      'admethod': admethod,
      'cost': cost,
      'startdate': startdate == null
             ? null
             : startdate!.toUtc().toIso8601String(),
      'target_gender': target_gender?.join(','),
      'target_ages': target_ages?.join(','),
      'adstate': adstate ?? 'SCHEDULED',
    };
  }
}