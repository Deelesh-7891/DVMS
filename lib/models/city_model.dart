class CityModel {
  final int cityId;
  final int stateId;
  final String cityName;
  final String locationName;
  final String locationType;
  final String pinCode;

  CityModel({
    required this.cityId,
    required this.stateId,
    required this.cityName,
    required this.locationName,
    required this.locationType,
    required this.pinCode,
  });

  factory CityModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CityModel(
      cityId: int.tryParse(
            json['CityId']?.toString() ?? '',
          ) ??
          0,

      stateId: int.tryParse(
            json['StateId']?.toString() ?? '',
          ) ??
          0,

      cityName:
          json['CityName']?.toString() ?? '',

      locationName:
          json['LocationName']?.toString() ?? '',

      locationType:
          json['LocationType']?.toString() ?? '',

      pinCode:
          json['PinCode']?.toString() ?? '',
    );
  }
}