import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/odometer_ocr_service.dart';
import '../../core/widgets/driver_picker_sheet.dart';
import '../../services/auth_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: int.tryParse(json['CityId']?.toString() ?? '') ?? 0,
      stateId: int.tryParse(json['StateId']?.toString() ?? '') ?? 0,
      cityName: json['CityName']?.toString() ?? '',
      locationName: json['LocationName']?.toString() ?? '',
      locationType: json['LocationType']?.toString() ?? '',
      pinCode: json['PinCode']?.toString() ?? '',
    );
  }
}


class VehicleModel {
  final int vehicleId;
  final String vehicleNumber;
  final String qrToken;
  final String modelName;

  VehicleModel({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.qrToken,
    required this.modelName,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    String clean(dynamic value) {
      if (value == null) return '';
      if (value is Map) {
        for (final key in [
          'QrToken', 'QRToken', 'qrToken', 'QR', 'qr',
          'Token', 'token', 'Value', 'value', 'Code', 'code',
        ]) {
          final nested = value[key];
          if (nested != null && nested.toString().trim().isNotEmpty) {
            return nested.toString().trim();
          }
        }
        return '';
      }
      final result = value.toString().trim();
      if (result.isEmpty || result.toLowerCase() == 'null') return '';
      return result;
    }

    String getValue(List<String> keys) {
      for (final key in keys) {
        final value = clean(json[key]);
        if (value.isNotEmpty) return value;
      }

      for (final parentKey in [
        'Vehicle', 'vehicle', 'VehicleData', 'vehicleData',
        'Details', 'details',
      ]) {
        final parent = json[parentKey];
        if (parent is Map) {
          for (final key in keys) {
            final value = clean(parent[key]);
            if (value.isNotEmpty) return value;
          }
        }
      }
      return '';
    }

    return VehicleModel(
      vehicleId: int.tryParse(getValue([
        'VehicleId', 'vehicleId', 'VehicleID', 'vehicleID', 'Id', 'id',
      ])) ?? 0,
      vehicleNumber: getValue([
        'VehicleNumber', 'vehicleNumber', 'VehicleNo', 'vehicleNo',
        'RegistrationNo', 'registrationNo', 'RegistrationNumber',
        'registrationNumber', 'RegNo', 'regNo', 'Number', 'number',
      ]),
      qrToken: getValue([
        'QrToken', 'QRToken', 'qrToken', 'VehicleQrToken',
        'vehicleQrToken', 'VehicleQRToken', 'VehicleQR', 'vehicleQR',
        'VehicleQr', 'vehicleQr', 'QR_TOKEN', 'QR', 'qr',
        'QrCode', 'QRCode', 'qrCode', 'Token', 'token',
        'VehicleToken', 'vehicleToken', 'UniqueToken', 'uniqueToken',
      ]),
      modelName: getValue([
        'ModelName', 'modelName', 'Model', 'model',
        'VehicleModel', 'vehicleModel',
      ]),
    );
  }
}

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({
    super.key,
  });

  @override
  State<ManualEntryScreen> createState() =>
      _ManualEntryScreenState();
}

class _ManualEntryScreenState
    extends State<ManualEntryScreen> {

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController tokenController =
      TextEditingController();

  final TextEditingController odometerController =
      TextEditingController();

  final TextEditingController driverController =
      TextEditingController();

  // Driver picked from the list (starts live tracking on gate-out). If the
  // guard then edits the name by hand, the pick no longer applies.
  int? selectedDriverId;
  String? pickedDriverName;
  bool get _pickedDriverStillValid =>
      selectedDriverId != null &&
      driverController.text.trim() == (pickedDriverName ?? "").trim();

  final TextEditingController salesExecutiveController =
      TextEditingController();

  final TextEditingController customerNameController =
      TextEditingController();

  final TextEditingController purposeController =
      TextEditingController();

  // Single "other location" field — the guard's own gate is always the
  // fixed side (shown read-only), so there's only ever one thing to pick,
  // regardless of Entry/Exit.
  final TextEditingController otherLocationController =
      TextEditingController();

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker _imagePicker =
      ImagePicker();

  // Original selected/captured image
  XFile? odometerImage;

  // Image bytes - works on Android + Web
  Uint8List? odometerImageBytes;

  bool isReadingOdometer = false;

  // ============================================================
  // SERVICE
  // ============================================================

  final AuthService _authService = AuthService();

  // ============================================================
  // SPEECH TO TEXT ONLY
  // ============================================================

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  bool _speechInitialized = false;
  String? _activeSpeechField;
  int _speechRequestId = 0;
  String _speechLocaleId = 'en_IN';

  String normalizeNumberSpeech(String input) {
    final text = input.toLowerCase().trim();
    const map = <String,String>{
      'zero':'0','oh':'0','o':'0','शून्य':'0','जीरो':'0',
      'one':'1','एक':'1','two':'2','to':'2','too':'2','दो':'2',
      'three':'3','तीन':'3','four':'4','for':'4','चार':'4',
      'five':'5','पांच':'5','पाँच':'5','six':'6','छह':'6','छः':'6',
      'seven':'7','सात':'7','eight':'8','आठ':'8','nine':'9','नौ':'9',
    };
    if (RegExp(r'^\s*[0-9, .-]+\s*$').hasMatch(text)) {
      return text.replaceAll(RegExp(r'[^0-9]'), '');
    }
    final tokens = text.replaceAll(RegExp(r'[,.-]'), ' ').split(RegExp(r'\s+'));
    final out = StringBuffer();
    for (final token in tokens) {
      if (map.containsKey(token)) out.write(map[token]);
      else if (RegExp(r'^\d+$').hasMatch(token)) out.write(token);
    }
    return out.toString().isNotEmpty ? out.toString() : text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String normalizeVehicleSpeech(String input) {
    final text = input.toLowerCase().trim();
    const map = <String,String>{
      'a':'a','ए':'a','ay':'a','b':'b','बी':'b','bee':'b','c':'c','सी':'c','see':'c',
      'd':'d','डी':'d','dee':'d','e':'e','ई':'e','f':'f','एफ':'f','g':'g','जी':'g',
      'h':'h','एच':'h','i':'i','आई':'i','j':'j','जे':'j','jay':'j','k':'k','के':'k','kay':'k',
      'l':'l','एल':'l','m':'m','एम':'m','n':'n','एन':'n','o':'o','ओ':'o','p':'p','पी':'p',
      'q':'q','क्यू':'q','r':'r','आर':'r','are':'r','s':'s','एस':'s','t':'t','टी':'t',
      'u':'u','यू':'u','v':'v','वी':'v','w':'w','डब्ल्यू':'w','x':'x','एक्स':'x',
      'y':'y','वाई':'y','z':'z','जेड':'z','zee':'z',
      'zero':'0','शून्य':'0','जीरो':'0','one':'1','एक':'1','two':'2','to':'2','दो':'2',
      'three':'3','तीन':'3','four':'4','for':'4','चार':'4','five':'5','पांच':'5','पाँच':'5',
      'six':'6','छह':'6','seven':'7','सात':'7','eight':'8','आठ':'8','nine':'9','नौ':'9',
    };
    final compact = text.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (RegExp(r'^[a-z]{2}[0-9]{1,2}[a-z]{0,3}[0-9]{1,4}$').hasMatch(compact)) return compact.toUpperCase();
    final out = StringBuffer();
    for (final token in text.replaceAll(RegExp(r'[,./_-]'), ' ').split(RegExp(r'\s+'))) {
      if (map.containsKey(token)) out.write(map[token]);
      else {
        final n=token.replaceAll(RegExp(r'[^0-9]'),'');
        if(n.isNotEmpty) out.write(n);
      }
    }
    return out.toString().toUpperCase();
  }

  Future<void> initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() { isListening=false; _activeSpeechField=null; });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() { isListening=false; _activeSpeechField=null; });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech error: ${error.errorMsg}'), backgroundColor: Colors.red));
          }
        },
      );
    } catch (e) {
      debugPrint('SPEECH INITIALIZATION ERROR: $e');
      _speechInitialized=false;
    }
  }

  Future<void> startListening({required String fieldName, required TextEditingController controller}) async {
    try {
      if (isListening) { await stopListening(); await Future.delayed(const Duration(milliseconds:250)); }
      if (!_speechInitialized) await initSpeech();
      if (!_speechInitialized || !mounted) return;
      setState(() { isListening=true; _activeSpeechField=fieldName; });
      await _speech.listen(
        localeId: _speechLocaleId, listenMode: stt.ListenMode.dictation, partialResults:true, cancelOnError:true,
        listenFor: const Duration(seconds:30), pauseFor: const Duration(seconds:3),
        onResult: (result) {
          if(!mounted) return;
          var text=result.recognizedWords.trim();
          if(text.isEmpty) return;
          if(fieldName=='odometer') text=normalizeNumberSpeech(text);
          controller.value=TextEditingValue(text:text,selection:TextSelection.collapsed(offset:text.length));
          if(result.finalResult) stopListening();
        },
      );
    } catch(e) { await stopListening(); }
  }

  Future<void> listenVehicle() async {
    try {
      if(isListening){await stopListening();await Future.delayed(const Duration(milliseconds:250));}
      if(!_speechInitialized) await initSpeech();
      if(!_speechInitialized||!mounted)return;
      setState(() { isListening = true; _activeSpeechField = 'vehicle'; });
      await _speech.listen(localeId:_speechLocaleId,listenMode:stt.ListenMode.dictation,partialResults:true,cancelOnError:true,listenFor:const Duration(seconds:15),pauseFor:const Duration(seconds:3),onResult:(result){
        if(!mounted)return; final spoken=result.recognizedWords.trim(); if(spoken.isEmpty)return;
        final normalized=normalizeVehicleSpeech(spoken).toLowerCase();
        final raw=spoken.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'),'');
        final matches=allVehicles.where((v){final n=v.vehicleNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'),''); return n==normalized||n==raw||n.contains(normalized)||normalized.contains(n);}).toList();
        if(matches.length == 1) {
          setState(() {
            selectedVehicle = matches.first;
            tokenController.clear();
          });
        }
        if(result.finalResult)stopListening();
      });
    }catch(e){await stopListening();}
  }

  Future<void> stopListening() async { try{await _speech.stop();}catch(_){} if(mounted)setState(() { isListening = false; _activeSpeechField = null; }); }

  Widget speechButton({required String fieldName, required TextEditingController controller}) {
    final active=isListening&&_activeSpeechField==fieldName;
    return IconButton(tooltip:active?'Stop listening':'Speak',icon:Icon(active?Icons.mic:Icons.mic_none,color:active?Colors.red:const Color(0xff2757B0),size:24),onPressed:()async{if(active){await stopListening();}else{await startListening(fieldName:fieldName,controller:controller);}});
  }

  String? convertMovementType(String text) {
    final v=text.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]'),'');
    if(v.contains('demo')||text.contains('डेमो'))return 'Demo';
    if(v.contains('testdrive')||text.contains('टेस्ट ड्राइव')||text.contains('टेस्टड्राइव'))return 'TestDrive';
    if(v.contains('service')||text.contains('सर्विस'))return 'Service';
    if(v.contains('workshop')||text.contains('वर्कशॉप'))return 'Workshop';
    if(v.contains('interbranch')||text.contains('इंटर ब्रांच')||text.contains('इंटरब्रांच'))return 'InterBranch';
    return null;
  }

  Future<void> listenMovementType() async {
    if(isListening){await stopListening();await Future.delayed(const Duration(milliseconds:250));}
    if(!_speechInitialized)await initSpeech(); if(!_speechInitialized||!mounted)return;
    setState(() { isListening = true; _activeSpeechField = 'movementType'; });
    await _speech.listen(localeId:_speechLocaleId,listenMode:stt.ListenMode.dictation,partialResults:true,cancelOnError:true,listenFor:const Duration(seconds:15),pauseFor:const Duration(seconds:3),onResult:(result){final m=convertMovementType(result.recognizedWords);if(m!=null&&mounted)setState(()=>selectedMovementType=m);if(result.finalResult)stopListening();});
  }

  // ============================================================
  // MOVEMENT
  // ============================================================

  // Direction is auto-detected server-side now (vehicle's own last
  // movement — see computeAutoDirection in dvms.js). No local state for
  // it here anymore.

  String? selectedMovementType;

  final List<String> movementTypes = [
    "Demo",
    "TestDrive",
    "Service",
    "Workshop",
    "InterBranch",
  ];

  // ============================================================
  // LOADING
  // ============================================================

  bool isSaving = false;

  // ============================================================
  // LOGIN / CITY / LOCATION DATA
  // ============================================================

  String gateCityName = '';
  int stateId = 0;

  List<CityModel> allCities = [];
  bool isLoadingCities = false;

  // ============================================================
  // VEHICLE DATA
  // ============================================================

  List<VehicleModel> allVehicles = [];
  bool isLoadingVehicles = false;
  VehicleModel? selectedVehicle;

  int? otherCityId;
  Map<String, dynamic>? selectedOtherLocation;

  // Result of the last save — what the SERVER auto-detected, shown on the
  // success confirmation rather than anything the guard picked.
  String? resultDirection;
  String? resultNewStatus;

  @override
  void initState() {
    super.initState();
    initSpeech();
    loadLoginData();
    loadCities();
    loadVehicles();
  }

  // ============================================================
  // LOAD LOGIN DATA
  // ============================================================

  Future<void> loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();

    String cityName = prefs.getString('cityName') ?? '';
    if (cityName.trim().isEmpty) {
      cityName = prefs.getString('CityName') ?? '';
    }

    int savedStateId = prefs.getInt('stateId') ?? 0;
    if (savedStateId == 0) {
      savedStateId = prefs.getInt('StateId') ?? 0;
    }

    if (!mounted) return;

    setState(() {
      gateCityName = cityName.trim();
      stateId = savedStateId;

    });

    debugPrint('LOGIN CITY: $gateCityName');
    debugPrint('STATE ID: $stateId');

    // If cities have already loaded, immediately apply the gate location
    // to the correct side for the current direction.
    if (allCities.isNotEmpty) {
      applyDirectionLocation();
    }
  }

  // ============================================================
  // GATE LOCATION DISPLAY
  //
  // Direction is auto-detected server-side now, and the guard's own gate
  // is pinned from their profile on the backend regardless — so this no
  // longer needs to resolve a CityId or fill either from/to controller,
  // it's purely for the read-only "Your Gate" label in the UI.
  // ============================================================

  void applyDirectionLocation() {
    debugPrint('GATE LOCATION (display only): $gateCityName');
  }

  // ============================================================
  // LOAD LOCATIONS / CITIES
  // ============================================================

  Future<void> loadVehicles() async {
    if (!mounted) return;

    setState(() {
      isLoadingVehicles = true;
    });
final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    try {
      // IMPORTANT:
      // Replace this URL if your backend uses a different vehicle endpoint.
      final response = await http.get(
        Uri.parse(
          'http://103.168.210.85:4001/api/vehicles',
        ),
        headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      );

      debugPrint(
        'VEHICLES API STATUS: ${response.statusCode}',
      );
      debugPrint(
        'VEHICLES API RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Vehicles API failed: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> rawVehicles = [];

      if (decoded is List) {
        rawVehicles = decoded;
      } else if (decoded is Map) {
        final dynamic data = decoded['data'];
        final dynamic vehicles = decoded['vehicles'];
        final dynamic result = decoded['result'];

        if (data is List) {
          rawVehicles = data;
        } else if (vehicles is List) {
          rawVehicles = vehicles;
        } else if (result is List) {
          rawVehicles = result;
        }
      }

      final loadedVehicles = rawVehicles
          .whereType<Map>()
          .map(
            (item) => VehicleModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (vehicle) =>
                vehicle.vehicleId != 0 ||
                vehicle.vehicleNumber.isNotEmpty ||
                vehicle.qrToken.isNotEmpty,
          )
          .toList();

      if (!mounted) return;

      setState(() {
        allVehicles = loadedVehicles;
        isLoadingVehicles = false;
      });

      debugPrint(
        'TOTAL VEHICLES: ${allVehicles.length}',
      );
    } catch (e) {
      debugPrint(
        'VEHICLE LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoadingVehicles = false;
        allVehicles = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load vehicles: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // VEHICLE SEARCH FIELD
  // ============================================================

  Widget vehicleSearchField() {
    return Autocomplete<VehicleModel>(
      displayStringForOption: (vehicle) =>
          vehicle.vehicleNumber.isNotEmpty
              ? vehicle.vehicleNumber
              : 'Vehicle ${vehicle.vehicleId}',

      optionsBuilder: (textEditingValue) {
        final searchText =
            textEditingValue.text.trim().toLowerCase();

        if (searchText.isEmpty) {
          return allVehicles;
        }

        return allVehicles.where((vehicle) {
          final vehicleNumber =
              vehicle.vehicleNumber.toLowerCase();
          final qrToken =
              vehicle.qrToken.toLowerCase();
          final modelName =
              vehicle.modelName.toLowerCase();
          final vehicleId =
              vehicle.vehicleId.toString();

          return vehicleNumber.contains(searchText) ||
              qrToken.contains(searchText) ||
              modelName.contains(searchText) ||
              vehicleId.contains(searchText);
        });
      },

      onSelected: (vehicle) {
        setState(() {
          selectedVehicle = vehicle;
          // QR Token is optional and is never sent during movement save.
          tokenController.clear();
        });

        debugPrint('======================================');
        debugPrint('SELECTED VEHICLE');
        debugPrint('VEHICLE ID: ${vehicle.vehicleId}');
        debugPrint('VEHICLE NO: ${vehicle.vehicleNumber}');
        debugPrint('MODEL: ${vehicle.modelName}');
        debugPrint('======================================');

      },

      fieldViewBuilder: (
        context,
        fieldController,
        focusNode,
        onFieldSubmitted,
      ) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search vehicle number...',
            prefixIcon: const Icon(
              Icons.directions_car,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                speechButton(fieldName: 'vehicle', controller: TextEditingController()),
                if (isLoadingVehicles)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(tooltip: 'Refresh vehicles', icon: const Icon(Icons.refresh), onPressed: loadVehicles),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (selectedVehicle != null) {
              setState(() {
                selectedVehicle = null;
                tokenController.clear();
              });
            }
          },
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },

      optionsViewBuilder: (
        context,
        onSelected,
        options,
      ) {
        final vehicleOptions = options.toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 320,
                maxWidth: 520,
              ),
              child: vehicleOptions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No vehicle found',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      shrinkWrap: true,
                      itemCount: vehicleOptions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vehicle =
                            vehicleOptions[index];

                        return InkWell(
                          onTap: () => onSelected(vehicle),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.blue
                                        .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.vehicleNumber
                                                .isNotEmpty
                                            ? vehicle.vehicleNumber
                                            : 'Vehicle ${vehicle.vehicleId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (vehicle.modelName.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            vehicle.modelName,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> loadCities() async {
    if (mounted) {
      setState(() {
        isLoadingCities = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://103.168.210.85:4001/api/cities'),
        headers: const {
          'Accept': 'application/json',
        },
      );

      debugPrint('CITIES API STATUS: \${response.statusCode}');
      debugPrint('CITIES API RESPONSE: \${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Cities API failed: \${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid cities API response');
      }

      final rawData = decoded['data'];

      if (rawData is! List) {
        throw Exception('City data not found');
      }

      final result = rawData
          .where((item) => item is Map)
          .map((item) => CityModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((city) => city.cityId > 0)
          .toList();

      if (!mounted) return;

      setState(() {
        allCities = result;
        isLoadingCities = false;
      });

      // Resolve login/gate location to CityId.
      if (gateCityName.isNotEmpty) {
        final defaultCity = allCities.cast<CityModel?>().firstWhere(
          (city) =>
              city!.cityName.trim().toLowerCase() ==
                  gateCityName.trim().toLowerCase() ||
              city.locationName.trim().toLowerCase() ==
                  gateCityName.trim().toLowerCase(),
          orElse: () => null,
        );

        if (defaultCity != null && mounted) {
          // Keep the gate location on the correct side only when
          // the selected movement type requires locations.
          if (isLocationRequired()) {
            applyDirectionLocation();
          }
        }
      }

      debugPrint('TOTAL LOCATIONS: \${allCities.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCities = false;
      });

      debugPrint('CITIES API ERROR: $e');
      showError('Unable to load locations');
    }
  }

  // ============================================================
  // SEARCH LOCATIONS
  // ============================================================

  List<Map<String, dynamic>> searchLocations(String query) {
    final search = query.trim().toLowerCase();

    Iterable<CityModel> source = allCities;

    if (search.isNotEmpty) {
      source = source.where((city) {
        return city.cityName.toLowerCase().contains(search) ||
            city.locationName.toLowerCase().contains(search) ||
            city.locationType.toLowerCase().contains(search) ||
            city.pinCode.toLowerCase().contains(search) ||
            city.cityId.toString().contains(search);
      });
    }

    return source.take(20).map((city) {
      return <String, dynamic>{
        'CityId': city.cityId,
        'StateId': city.stateId,
        'CityName': city.cityName,
        'LocationName': city.locationName,
        'LocationType': city.locationType,
        'PinCode': city.pinCode,
      };
    }).toList();
  }

  // ============================================================
  // LOCATION SEARCH FIELD
  // ============================================================

  Widget locationSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<Map<String, dynamic>> onSelected,
    String Function()? speechText,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (location) =>
          location['CityName']?.toString() ??
          location['LocationName']?.toString() ??
          '',

      optionsBuilder: (value) {
        return searchLocations(value.text);
      },

      onSelected: onSelected,

      fieldViewBuilder: (
        context,
        fieldController,
        focusNode,
        onFieldSubmitted,
      ) {
        if (fieldController.text != controller.text) {
          fieldController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(
              offset: controller.text.length,
            ),
          );
        }

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,

          onChanged: (value) {
            // If the user changes the selected text manually,
            // invalidate the previous CityId/selection.
            if (controller == otherLocationController) {
              if (selectedOtherLocation?['LocationName']?.toString() != value &&
                  selectedOtherLocation?['CityName']?.toString() != value) {
                otherCityId = null;
                selectedOtherLocation = null;
              }
            }

            controller.value = fieldController.value;
          },

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isLoadingCities ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xff2757B0),
                width: 2,
              ),
            ),
          ),
        );
      },

      optionsViewBuilder: (
        context,
        onSelected,
        options,
      ) {
        final optionList = options.toList();

        if (optionList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 36,
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final location = optionList[index];

                  final locationName =
                      location['LocationName']?.toString() ?? '';
                  final cityName =
                      location['CityName']?.toString() ?? '';
                  final cityId =
                      location['CityId']?.toString() ?? '';
                  final locationType =
                      location['LocationType']?.toString() ?? '';
                  final pinCode =
                      location['PinCode']?.toString() ?? '';

                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xff2458A6),
                    ),
                    title: Text(
                      locationName.isNotEmpty
                          ? locationName
                          : cityName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (cityName.isNotEmpty) cityName,
                        // if (cityId.isNotEmpty) 'CityId: $cityId',
                        if (locationType.isNotEmpty) locationType,
                        // if (pinCode.isNotEmpty) 'PIN: $pinCode',
                      ].join(' • '),
                    ),
                    onTap: () => onSelected(location),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OPEN ODOMETER CAMERA
  // ============================================================

  Future<void> openOdometerCamera() async {
    try {
      debugPrint(
        "======================================",
      );

      debugPrint(
        "OPEN ODOMETER CAMERA",
      );

      debugPrint(
        "======================================",
      );

      final XFile? image =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      // --------------------------------------------------------
      // USER CANCELLED CAMERA
      // --------------------------------------------------------

      if (image == null) {
        debugPrint(
          "CAMERA CANCELLED",
        );

        return;
      }

      // --------------------------------------------------------
      // READ IMAGE BYTES
      // --------------------------------------------------------

      final Uint8List bytes =
          await image.readAsBytes();

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SAVE IMAGE
      // --------------------------------------------------------

      setState(() {
        odometerImage = image;
        odometerImageBytes = bytes;
        isReadingOdometer = true;
      });

      // Best-effort OCR — same digit-extraction approach as the web's
      // Tesseract.js odometer reader on fuel.html. Never blocks manual
      // entry: the field stays editable either way, this just pre-fills it.
      final reading =
          await OdometerOcrService.recognizeFromPath(image.path);

      if (!mounted) return;

      setState(() {
        isReadingOdometer = false;
        if (reading != null) {
          odometerController.text = reading;
        }
      });

      if (reading != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Detected $reading km — please verify & correct if wrong.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      debugPrint(
        "======================================",
      );

      debugPrint(
        "ODOMETER IMAGE CAPTURED",
      );

      debugPrint(
        "IMAGE PATH: ${image.path}",
      );

      debugPrint(
        "IMAGE BYTES: ${bytes.length}",
      );

      debugPrint(
        "ODOMETER: "
        "${odometerController.text.trim()}",
      );

      debugPrint(
        "======================================",
      );

    } catch (e) {

      debugPrint(
        "ODOMETER CAMERA ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      showError(
        "Unable to open camera: $e",
      );
    }
  }

  // ============================================================
  // RETAKE IMAGE
  // ============================================================

  Future<void> retakeOdometerImage() async {
    await openOdometerCamera();
  }

  // ============================================================
  // LOCATION REQUIRED
  // Service / Workshop / InterBranch
  // ============================================================

  bool isLocationRequired() {
    // Demo / TestDrive = NO movement locations.
    // Service / Workshop / InterBranch = movement locations required.
    return selectedMovementType == "Service" ||
        selectedMovementType == "Workshop" ||
        selectedMovementType == "InterBranch";
  }

  // ============================================================
  // VALIDATE FORM
  // ============================================================

  bool validateForm() {

    // ==========================================================
    // QR TOKEN
    // ==========================================================

    if (selectedVehicle == null) {
      showError(
        "Please select a vehicle",
      );

      return false;
    }

    // QR Token is NOT required.
    // Movement save uses the selected vehicleId only.
    if (selectedVehicle!.vehicleId == 0) {
      showError(
        "Selected vehicle has invalid Vehicle ID",
      );
      return false;
    }

    // ==========================================================
    // ODOMETER
    // ==========================================================

    final String odometerText =
        odometerController.text
            .trim()
            .replaceAll(",", "");

    if (odometerText.isEmpty) {

      showError(
        "Enter Odometer",
      );

      return false;
    }

    final int? odometer =
        int.tryParse(
      odometerText,
    );

    if (odometer == null) {

      showError(
        "Enter valid Odometer",
      );

      return false;
    }

    if (odometer < 0) {

      showError(
        "Odometer cannot be negative",
      );

      return false;
    }

    // ==========================================================
    // ODOMETER IMAGE
    // ==========================================================

    // if (odometerImageBytes == null) {

    //   showError(
    //     "Please take Odometer Image",
    //   );

    //   return false;
    // }

    // ==========================================================
    // DRIVER
    // ==========================================================

    if (driverController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Driver Name",
      );

      return false;
    }

    // ==========================================================
    // MOVEMENT TYPE
    // ==========================================================

    if (selectedMovementType == null ||
        selectedMovementType!
            .trim()
            .isEmpty) {

      showError(
        "Select Movement Type",
      );

      return false;
    }

    // ==========================================================
    // SALES EXECUTIVE
    // ==========================================================

    if (salesExecutiveController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Sales Executive",
      );

      return false;
    }

    // ==========================================================
    // CUSTOMER
    // ==========================================================

    if (customerNameController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Customer Name",
      );

      return false;
    }

    // ==========================================================
    // PURPOSE
    // ==========================================================

    if (purposeController.text
        .trim()
        .isEmpty) {

      showError(
        "Enter Purpose",
      );

      return false;
    }

    // ==========================================================
    // OTHER LOCATION
    // Demo / TestDrive = hidden, not required
    // Service / Workshop / InterBranch = required
    // The guard's own gate is fixed server-side regardless of direction,
    // so there's only ever this one field to validate.
    // ==========================================================

    if (isLocationRequired()) {
      if (otherLocationController.text.trim().isEmpty) {
        showError('Select the other location');
        return false;
      }

      if (otherCityId == null || otherCityId == 0) {
        showError('Select the other location from the list');
        return false;
      }

      debugPrint('VALID OTHER CITY ID: $otherCityId');
    }

    return true;
  }

  // ============================================================
  // SAVE MOVEMENT
  // ============================================================

  Future<void> saveMovement() async {

    if (isSaving) {
      return;
    }

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (!validateForm()) {
      return;
    }

    try {

      setState(() {
        isSaving = true;
      });

      // ========================================================
      // SHARED PREFERENCES
      // ========================================================

      final SharedPreferences prefs = await SharedPreferences .getInstance();

      // ========================================================
      // BRANCH ID
      // ========================================================

      // final int branchId = prefs.getInt( "BranchId", ) ?? 0;


    final int branchId =  prefs.getInt('BranchId') ?? 1;
      if (branchId == 0) {

        throw Exception(
          "BranchId not found. Please login again.",
        );
      }

      // ========================================================
      // USER ID
      // ========================================================

      final int? userId =
          prefs.getInt(
        "UserId",
      );

      // ========================================================
      // VEHICLE
      // ========================================================
      // QR Token is NOT required for movement save.
      // Only vehicleId is sent to the Movement API.
      final int vehicleId = selectedVehicle!.vehicleId;

      if (vehicleId == 0) {
        throw Exception(
          "Selected vehicle has invalid Vehicle ID",
        );
      }

      // ========================================================
      // DRIVER
      // ========================================================

      final String driverName =
          driverController.text.trim();

      // ========================================================
      // SALES EXECUTIVE
      // ========================================================

      final String salesExecutive =
          salesExecutiveController
              .text
              .trim();

      // ========================================================
      // CUSTOMER
      // ========================================================

      final String customerName =
          customerNameController
              .text
              .trim();

      // ========================================================
      // LOCATION — single field; the gate side is fixed server-side.
      // ========================================================

      final String otherLocation =
          otherLocationController
              .text
              .trim();

      // ========================================================
      // PURPOSE
      // ========================================================

      final String purpose =
          purposeController
              .text
              .trim();

      // ========================================================
      // MOVEMENT TYPE
      // ========================================================

      final String movementType =
          selectedMovementType ?? "";

      // ========================================================
      // ODOMETER
      // ========================================================

      final int? odometer =
          int.tryParse(
        odometerController.text
            .trim()
            .replaceAll(
              ",",
              "",
            ),
      );

      if (odometer == null) {

        throw Exception(
          "Invalid Odometer",
        );
      }

      // ========================================================
      // DEBUG
      // ========================================================

      print(
        "======================================",
      );

      print(
        "MANUAL MOVEMENT SAVE",
      );

      print(
        "======================================",
      );

      print(
        "UserId          : $userId",
      );

      print(
        "BranchId        : $branchId",
      );

      print(
        "VehicleId       : ${selectedVehicle!.vehicleId}",
      );

      // print(
      //   "QR Token        : $qrToken",
      // );

      print(
        "Other Location  : $otherLocation ($otherCityId)",
      );

      print(
        "Odometer        : $odometer",
      );

      print(
        "Odometer Image  : "
        "${odometerImage?.path}",
      );

      print(
        "Image Bytes     : "
        "${odometerImageBytes?.length}",
      );

      print(
        "Driver Name     : $driverName",
      );

      print(
        "Movement Type   : $movementType",
      );

      print(
        "Sales Executive : $salesExecutive",
      );

      print(
        "Customer Name   : $customerName",
      );

      print(
        "Other Location  : $otherLocation",
      );

      print(
        "Purpose         : $purpose",
      );

      print(
        "======================================",
      );

      // ========================================================
      // API CALL
      // ========================================================

      final movementResult = await _authService.movementSave(

        branchId:
            branchId,

        // QR token is used only to identify the selected vehicle in the UI.
        // Do NOT send qrToken to the movement-save API.
        vehicleId: selectedVehicle!.vehicleId,

        txnDate:
            DateTime.now()
                .toIso8601String(),

        // direction: left null — the server auto-detects Entry/Exit from
        // the vehicle's own last movement now.

        odometer:
            odometer,

        driverName:
            driverName,

        driverId:
            _pickedDriverStillValid ? selectedDriverId : null,

        movementType:
            movementType,

        salesExecutive:
            salesExecutive,

        customerName:
            customerName,

        otherCityIdOverride:
            otherCityId,

        purpose:
            purpose,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      resultDirection = movementResult["direction"]?.toString();
      resultNewStatus = movementResult["newStatus"]?.toString();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            resultDirection == "Exit"
                ? "Vehicle OUT recorded"
                : resultDirection == "Entry"
                    ? "Vehicle IN recorded"
                    : "Movement Saved Successfully",
          ),

          backgroundColor:
              Colors.green,

          duration:
              Duration(
            seconds: 2,
          ),
        ),
      );

      // ========================================================
      // CLEAR FORM
      // ========================================================

      tokenController.clear();

      if (mounted) {
        setState(() {
          selectedVehicle = null;
        });
      }

      odometerController.clear();

      driverController.clear();
      selectedDriverId = null;
      pickedDriverName = null;

      salesExecutiveController.clear();

      customerNameController.clear();

      purposeController.clear();

      otherLocationController.clear();

      setState(() {

        otherCityId = null;
        selectedOtherLocation = null;
        resultDirection = null;
        resultNewStatus = null;

        odometerImage =
            null;

        odometerImageBytes =
            null;

        isReadingOdometer =
            false;

        selectedMovementType =
            null;
      });

      // Default is Entry, but Demo is selected only after user chooses
      // a movement type. Do not force a hidden location here.
      if (isLocationRequired()) {
        applyDirectionLocation();
      }

    } catch (e) {

      if (!mounted) {
        return;
      }

      print(
        "======================================",
      );

      print(
        "MOVEMENT SAVE ERROR",
      );

      print(
        "$e",
      );

      print(
        "======================================",
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            "Movement Save Error: $e",
          ),

          backgroundColor:
              Colors.red,
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void showError(
    String message,
  ) {

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            Colors.red,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _speechRequestId++;
    _speech.stop();

    tokenController.dispose();

    odometerController.dispose();

    driverController.dispose();

    salesExecutiveController.dispose();

    customerNameController.dispose();

    purposeController.dispose();

    otherLocationController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xffEEF2F7),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar:
          AppBar(

        backgroundColor:
            const Color(0xff12386B),

        elevation:
            0,

        foregroundColor:
            Colors.white,

        title:
            const Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              "📝 Manual Entry",

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,

                fontSize:
                    22,
              ),
            ),

            SizedBox(
              height: 4,
            ),

            Text(
              "When the camera can't read the sticker",

              style:
                  TextStyle(
                fontSize:
                    14,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Voice language',
            icon: Text(_speechLocaleId == 'hi_IN' ? 'हिं' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onSelected: (value) => setState(() => _speechLocaleId = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en_IN', child: Text('English (India)')),
              PopupMenuItem(value: 'hi_IN', child: Text('हिंदी (India)')),
            ],
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Card(

          elevation:
              3,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          child:
              Padding(

            padding:
                const EdgeInsets.all(
              18,
            ),

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // QR TOKEN
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: buildTitle(
                        "Vehicle",
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                vehicleSearchField(),

                const SizedBox(
                  height: 10,
                ),

                if (selectedVehicle != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Vehicle Selected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vehicle No: ${selectedVehicle!.vehicleNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (selectedVehicle!.modelName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Model: ${selectedVehicle!.modelName}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // DIRECTION — auto-detected server-side now (no more
                // Entry/Exit toggle here; the backend figures it out from
                // the vehicle's own last movement).
                // ==================================================

                // ==================================================
                // ODOMETER + DRIVER
                // ==================================================

                // ==================================================
                // ODOMETER
                // ==================================================

                buildTitle("Odometer (km)"),

                const SizedBox(height: 8),

                TextField(
                  controller: odometerController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: "Enter odometer",
                    prefixIcon: const Icon(
                      Icons.speed,
                      color: Color(0xff64748B),
                    ),
                    suffixText: "KM",
                    suffixIcon: speechButton(fieldName: 'odometer', controller: odometerController),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xff2757B0),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (isReadingOdometer)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Reading odometer from photo…",
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                // ==================================================
                // TAKE ODOMETER IMAGE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isReadingOdometer ? null : openOdometerCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      odometerImageBytes == null
                          ? "Take Odometer Image"
                          : "Retake Odometer Image",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff12386B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DRIVER NAME
                // ==================================================

                buildTitle("Driver Name"),

                const SizedBox(height: 8),

                buildField(
                  controller: driverController,
                  hint: "Enter driver name",
                  icon: Icons.person,
                  capitalize: true,
                  speechFieldName: "driver",
speechText: () {
                    final value = driverController.text.trim();
                    return value.isEmpty
                        ? ""
                        : "Driver name, $value.";
                  },
                ),

                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final d = await showDriverPicker(context);
                        if (d == null) return;
                        setState(() {
                          pickedDriverName = d["DriverName"]?.toString() ?? "";
                          selectedDriverId = (d["DriverId"] as num?)?.toInt();
                          driverController.text = pickedDriverName!;
                        });
                      },
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text("Select from driver list"),
                    ),
                    if (_pickedDriverStillValid)
                      const Expanded(
                        child: Text(
                          "Tracked live while out",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                // ==================================================
                // ODOMETER IMAGE PREVIEW
                // ==================================================

                if (odometerImageBytes != null) ...[

                  const SizedBox(
                    height: 18,
                  ),

                  buildTitle(
                    "Odometer Image",
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  ClipRRect(

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    child:
                        Image.memory(

                      odometerImageBytes!,

                      width:
                          double.infinity,

                      height:
                          220,

                      fit:
                          BoxFit.cover,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        OutlinedButton.icon(

                      onPressed:
                          retakeOdometerImage,

                      icon:
                          const Icon(
                        Icons.camera_alt,
                      ),

                      label:
                          const Text(
                        "Retake Odometer Photo",
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // MOVEMENT TYPE
                // ==================================================

                buildTitle(
                  "Movement Type",
                ),

                const SizedBox(
                  height: 8,
                ),

                DropdownButtonFormField<
                    String>(

                  value:
                      selectedMovementType,

                  isExpanded:
                      true,

                  decoration:
                      InputDecoration(

                    hintText:
                        "Select movement type",

                    prefixIcon:
                        const Icon(
                      Icons.swap_horiz,
                    ),

                    suffixIcon: IconButton(
                       tooltip: isListening &&
                               _activeSpeechField == "movementType"
                           ? "Stop listening"
                           : "Speak movement type",
                       icon: Icon(
                         isListening &&
                                 _activeSpeechField == "movementType"
                             ? Icons.mic
                             : Icons.mic_none,
                         color: isListening &&
                                 _activeSpeechField == "movementType"
                             ? Colors.red
                             : const Color(0xff2757B0),
                       ),
                       onPressed: () async {
                         if (isListening &&
                             _activeSpeechField == "movementType") {
                           await stopListening();
                         } else {
                           await listenMovementType();
                         }
                       },
                     ),

                     filled:
                        true,

                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey
                                .shade300,
                      ),
                    ),
                  ),

                  items:
                      movementTypes
                          .map(
                    (
                      type,
                    ) {

                      return
                          DropdownMenuItem<
                              String>(

                        value:
                            type,

                        child:
                            Text(
                          type,
                        ),
                      );
                    },
                  ).toList(),

                  onChanged:
                      (
                    value,
                  ) {

                    setState(() {
                      selectedMovementType = value;

                      // Demo / TestDrive:
                      // hide movement location and clear old values.
                      if (value == "Demo" || value == "TestDrive") {
                        otherLocationController.clear();
                        otherCityId = null;
                        selectedOtherLocation = null;
                      }
                    });

                    // Service / Workshop / InterBranch:
                    // show movement locations and apply Login/Gate
                    // location according to Entry / Exit.
                    if (value == "Service" ||
                        value == "Workshop" ||
                        value == "InterBranch") {
                      applyDirectionLocation();
                    }
                  },
                ),

                // ==================================================
                // FROM / TO LOCATION SEARCH
                // ==================================================
                // Only Service / Workshop / InterBranch are shown.
                // Demo / TestDrive are hidden.
                // ==================================================

                if (isLocationRequired()) ...[
                  const SizedBox(height: 20),

                  // ==================================================
                  // MOVEMENT LOCATIONS — Direction is auto-detected
                  // server-side now, so there's just one gate display
                  // (read-only, always shown) and one searchable field
                  // for the other side, regardless of Entry/Exit.
                  // ==================================================

                  buildTitle('Movement Locations'),

                  const SizedBox(height: 10),

                  buildTitle('Your Gate'),

                  const SizedBox(height: 8),

                  TextField(
                    enabled: false,
                    controller: TextEditingController(
                      text: gateCityName.trim().isEmpty
                          ? 'Gate location not set'
                          : gateCityName,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Login / Gate Location',
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xff64748B),
                      ),
                      suffixIcon: null,
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  buildTitle('Other Location'),

                  const SizedBox(height: 8),

                  locationSearchField(
                    controller: otherLocationController,
                    hint: 'Type 2–3 letters to search...',
                    icon: Icons.location_searching,
                    onSelected: (location) {
                      final cityName =
                          location['CityName']?.toString() ?? '';
                      final locationName =
                          location['LocationName']?.toString() ?? '';

                      setState(() {
                        selectedOtherLocation = location;

                        otherCityId = int.tryParse(
                          location['CityId']?.toString() ?? '',
                        );

                        otherLocationController.text =
                            locationName.isNotEmpty
                                ? locationName
                                : cityName;
                      });

                      debugPrint(
                        'OTHER LOCATION CITY NAME: $cityName',
                      );
                      debugPrint(
                        'OTHER LOCATION: $locationName',
                      );
                      debugPrint(
                        'OTHER LOCATION CITY ID: $otherCityId',
                      );
                    },
                  ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SALES EXECUTIVE + CUSTOMER
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Expanded(
                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          buildTitle(
                            "Sales Executive",
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          buildField(
                            controller:
                                salesExecutiveController,

                            hint:
                                "Enter sales executive",

                            icon: Icons .person_outline,
                            capitalize: true,
                            speechFieldName: "salesExecutive",
speechText: () {
                              final value =
                                  salesExecutiveController.text.trim();
                              return value.isEmpty
                                  ? ""
                                  : "Sales executive, $value.";
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          buildTitle(
                            "Customer Name",
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          buildField(
                            controller:
                                customerNameController,

                            hint:
                                "Enter customer name",

                            icon:
                                Icons.person,
                            capitalize: true,
                            speechFieldName: "customerName",
speechText: () {
                              final value =
                                  customerNameController.text.trim();
                              return value.isEmpty
                                  ? ""
                                  : "Customer name, $value.";
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                 const SizedBox(height: 20),

                 // ==================================================
                 // PURPOSE
                 // ==================================================


                buildTitle(
                  "Purpose",
                ),

                const SizedBox(
                  height: 8,
                ),

                buildField(
                  controller: purposeController,

                  hint: "e.g. Customer demo drive – Model X",

                  icon: Icons
                          .description_outlined,

                  maxLines:
                      2,

                  speechFieldName: "purpose",
speechText: () {
                    final value = purposeController.text.trim();
                    return value.isEmpty
                        ? ""
                        : "Purpose, $value.";
                  },
                ),

                const SizedBox(
                  height: 30,
                ),
                const SizedBox(height: 12),

                // ==================================================
                // RECORD MOVEMENT
                // ==================================================

                SizedBox(

                  width:
                      double.infinity,

                  height:
                      55,

                  child:
                      ElevatedButton.icon(

                    style:
                        ElevatedButton
                            .styleFrom(

                      backgroundColor:
                          const Color(
                        0xff2757B0,
                      ),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),

                    onPressed:
                        isSaving
                            ? null
                            : saveMovement,

                    icon:
                        isSaving

                            ? const SizedBox(
                                width:
                                    20,

                                height:
                                    20,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,

                                  color:
                                      Colors.white,
                                ),
                              )

                            : const Icon(
                                Icons
                                    .save_outlined,
                              ),

                    label:
                        Text(

                      isSaving
                          ? "Saving..."
                          : "Record Movement",

                      style:
                          const TextStyle(
                        fontSize:
                            17,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget buildTitle(
    String title,
  ) {

    return Text(

      title,

      style:
          const TextStyle(

        fontWeight:
            FontWeight.bold,

        fontSize:
            13,

        color:
            Color(
          0xff4B5B73,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================



  Widget buildField({required TextEditingController controller, required IconData icon, String? hint, TextInputType keyboard=TextInputType.text, int maxLines=1, bool capitalize=true, String Function()? speechText, String? speechFieldName}) {
    return TextField(
      controller:controller, keyboardType:keyboard, maxLines:maxLines,
      textCapitalization:capitalize?TextCapitalization.words:TextCapitalization.none,
      decoration:InputDecoration(hintText:hint,prefixIcon:Icon(icon,color:const Color(0xff64748B)),suffixIcon:speechFieldName==null?null:speechButton(fieldName:speechFieldName,controller:controller),filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:15),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:Colors.grey.shade300)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:Colors.grey.shade300)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xff2757B0),width:2))),
    );
  }

}