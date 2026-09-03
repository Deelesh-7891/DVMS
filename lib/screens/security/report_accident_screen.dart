import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ReportAccidentScreen extends StatefulWidget {
  const ReportAccidentScreen({super.key});

  @override
  State<ReportAccidentScreen> createState() =>
      _ReportAccidentScreenState();
}

class _ReportAccidentScreenState extends State<ReportAccidentScreen> {
  static const String baseUrl = "http://103.168.210.85:4001/api";

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _accidents = [];
  List<Map<String, dynamic>> _vehicles = [];

  bool _loadingAccidents = false;
  bool _loadingVehicles = false;
  String? _vehicleLoadError;

  // ============================================================
  // SPEECH TO TEXT
  // ============================================================
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadAccidents();
    _loadVehicles();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint("SPEECH STATUS: $status");

          if (!mounted) return;

          if (status == "done" || status == "notListening") {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint("SPEECH ERROR: $error");

          if (!mounted) return;

          setState(() {
            _isListening = false;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _speechReady = available;
      });
    } catch (e) {
      debugPrint("SPEECH INIT ERROR: $e");

      if (!mounted) return;

      setState(() {
        _speechReady = false;
      });
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    if (token == null || token.trim().isEmpty) {
      throw Exception("Authorization token not found. Please login again.");
    }

    return token;
  }

  // ============================================================
  // ACCIDENT LIST
  // ============================================================
  Future<void> _loadAccidents() async {
    try {
      if (mounted) {
        setState(() => _loadingAccidents = true);
      }

      final token = await _getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/accidents"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("ACCIDENT LIST STATUS: ${response.statusCode}");
      debugPrint("ACCIDENT LIST RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Accident list failed: ${response.statusCode} ${response.body}",
        );
      }

      final decoded = jsonDecode(response.body);

      dynamic rawData;

      if (decoded is List) {
        rawData = decoded;
      } else if (decoded is Map) {
        rawData = decoded["data"] ??
            decoded["accidents"] ??
            decoded["result"] ??
            [];
      }

      final result = <Map<String, dynamic>>[];

      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map) {
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _accidents = result;
        _loadingAccidents = false;
      });
    } catch (e) {
      debugPrint("ACCIDENT LIST ERROR: $e");

      if (!mounted) return;

      setState(() => _loadingAccidents = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load accidents: $e")),
      );
    }
  }

  // ============================================================
  // VEHICLES
  // ============================================================
  Future<void> _loadVehicles() async {
    try {
      if (mounted) {
        setState(() {
          _loadingVehicles = true;
          _vehicleLoadError = null;
        });
      }

      final token = await _getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/vehicles"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("VEHICLES STATUS: ${response.statusCode}");
      debugPrint("VEHICLES RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Vehicles failed: ${response.statusCode} ${response.body}",
        );
      }

      final decoded = jsonDecode(response.body);

      dynamic rawData;

      if (decoded is List) {
        rawData = decoded;
      } else if (decoded is Map) {
        rawData = decoded["data"] ??
            decoded["vehicles"] ??
            decoded["result"] ??
            [];
      }

      final result = <Map<String, dynamic>>[];

      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);

            // Support common casing variations.
            final id = _extractVehicleId(map);
            final reg = _extractRegistration(map);

            // Keep the item if either ID or registration exists.
            if (id != null || reg.isNotEmpty) {
              result.add(map);
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _vehicles = result;
        _loadingVehicles = false;
        if (result.isEmpty) {
          _vehicleLoadError =
              "Vehicle list is empty. You can enter Vehicle ID manually.";
        }
      });
    } catch (e) {
      debugPrint("VEHICLES ERROR: $e");

      if (!mounted) return;

      setState(() {
        _loadingVehicles = false;
        _vehicleLoadError = e.toString();
      });
    }
  }

  int? _extractVehicleId(Map<String, dynamic> vehicle) {
    final value = vehicle["VehicleId"] ??
        vehicle["vehicleId"] ??
        vehicle["vehicleID"] ??
        vehicle["vehicle_id"] ??
        vehicle["id"];

    return int.tryParse(value?.toString() ?? "");
  }

  String _extractRegistration(Map<String, dynamic> vehicle) {
    return (vehicle["RegistrationNo"] ??
            vehicle["registrationNo"] ??
            vehicle["registrationNO"] ??
            vehicle["registration_no"] ??
            vehicle["RegNo"] ??
            vehicle["regNo"] ??
            vehicle["RegistrationNumber"] ??
            "")
        .toString();
  }

  String _extractModel(Map<String, dynamic> vehicle) {
    return (vehicle["Model"] ??
            vehicle["model"] ??
            vehicle["VehicleModel"] ??
            vehicle["vehicleModel"] ??
            "")
        .toString();
  }

  String _vehicleLabel(Map<String, dynamic> vehicle) {
    final reg = _extractRegistration(vehicle);
    final model = _extractModel(vehicle);

    if (reg.isEmpty && model.isEmpty) {
      final id = _extractVehicleId(vehicle);
      return id == null ? "Vehicle" : "Vehicle ID $id";
    }

    if (model.isEmpty) return reg;
    if (reg.isEmpty) return model;

    return "$reg • $model";
  }

  // ============================================================
  // SEARCHABLE VEHICLE SELECT
  // ============================================================

  Future<Map<String, dynamic>?> _searchAndSelectVehicle(
    BuildContext context,
  ) async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredVehicles = List.from(_vehicles);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void search(String value) {
              final q = value.trim().toLowerCase();

              setDialogState(() {
                if (q.isEmpty) {
                  filteredVehicles = List.from(_vehicles);
                } else {
                  filteredVehicles = _vehicles.where((vehicle) {
                    final id =
                        (_extractVehicleId(vehicle)?.toString() ?? "")
                            .toLowerCase();
                    final registration =
                        _extractRegistration(vehicle).toLowerCase();
                    final model = _extractModel(vehicle).toLowerCase();
                    final label = _vehicleLabel(vehicle).toLowerCase();

                    return id.contains(q) ||
                        registration.contains(q) ||
                        model.contains(q) ||
                        label.contains(q);
                  }).toList();
                }
              });
            }

            return AlertDialog(
              title: const Text(
                "Select Vehicle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: search,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "Search registration / model",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  search("");
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredVehicles.isEmpty
                          ? const Center(
                              child: Text(
                                "No vehicle found",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = filteredVehicles[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.directions_car),
                                    ),
                                    title: Text(
                                      _vehicleLabel(vehicle),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(
                                        dialogContext,
                                        vehicle,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  // ============================================================
  // PHOTO UPLOAD
  // Backend expects multipart field name = "file"
  // ============================================================
  Future<int?> _uploadPhoto(XFile photo) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/attachments"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.headers["Accept"] = "application/json";

    request.fields["entityType"] = "AccidentReport";

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: photo.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          photo.path,
          filename: photo.name,
        ),
      );
    }

    debugPrint("PHOTO UPLOAD START");

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint("PHOTO UPLOAD STATUS: ${response.statusCode}");
    debugPrint("PHOTO UPLOAD RESPONSE: ${response.body}");

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      String message = response.body;

      try {
        final error = jsonDecode(response.body);
        if (error is Map) {
          message =
              (error["error"] ?? error["message"] ?? response.body).toString();
        }
      } catch (_) {}

      throw Exception("Photo upload failed: $message");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map) {
      final id = decoded["attachmentId"] ??
          decoded["AttachmentId"] ??
          decoded["id"];

      return int.tryParse(id?.toString() ?? "");
    }

    return null;
  }

  // ============================================================
  // SAVE ACCIDENT
  // ============================================================
  Future<Map<String, dynamic>> _saveAccidentApi({
    required int vehicleId,
    required DateTime captured,
    required String description,
    int? attachmentId,
  }) async {
    final token = await _getToken();

    final body = {
      "VehicleId": vehicleId,
      "CapturedAt": captured.toIso8601String(),
      "Description": description.trim(),
      "AttachmentId": attachmentId,
    };

    debugPrint("======================================");
    debugPrint("ACCIDENT SAVE API");
    debugPrint("URL: $baseUrl/accidents");
    debugPrint("REQUEST BODY: ${jsonEncode(body)}");
    debugPrint("======================================");

    final response = await http.post(
      Uri.parse("$baseUrl/accidents"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    debugPrint("ACCIDENT SAVE STATUS: ${response.statusCode}");
    debugPrint("ACCIDENT SAVE RESPONSE: ${response.body}");

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      String message = response.body;

      try {
        final error = jsonDecode(response.body);
        if (error is Map) {
          message =
              (error["error"] ?? error["message"] ?? response.body).toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  // ============================================================
  // FILTER
  // ============================================================
  List<Map<String, dynamic>> get filteredAccidents {
    final q = _searchController.text.trim().toLowerCase();

    if (q.isEmpty) return _accidents;

    return _accidents.where((item) {
      final vehicle = (item["RegistrationNo"] ??
              item["vehicle"] ??
              item["registrationNo"] ??
              "")
          .toString()
          .toLowerCase();

      final model =
          (item["Model"] ?? item["model"] ?? "").toString().toLowerCase();

      final description = (item["Description"] ??
              item["description"] ??
              "")
          .toString()
          .toLowerCase();

      return vehicle.contains(q) ||
          model.contains(q) ||
          description.contains(q);
    }).toList();
  }

  String _formatCapturedDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return "-";

    try {
      final date = DateTime.parse(value.toString());
      return DateFormat("dd-MM-yyyy hh:mm a").format(date.toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // ADD ACCIDENT
  // ============================================================
  Future<void> _addAccident() async {
    int? selectedVehicleId;

    final manualVehicleIdController = TextEditingController();
    final manualVehicleController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime captured = DateTime.now();

    XFile? selectedPhoto;

    bool saving = false;
    bool listening = false;
    bool manualVehicle = _vehicles.isEmpty;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickPhoto(ImageSource source) async {
              try {
                final picker = ImagePicker();

                final photo = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                  maxWidth: 1600,
                );

                if (photo == null) return;

                setDialogState(() {
                  selectedPhoto = photo;
                });
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Photo error: $e")),
                );
              }
            }

            Future<void> choosePhoto() async {
              await showModalBottomSheet(
                context: context,
                builder: (sheetContext) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text("Camera"),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await pickPhoto(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text("Gallery"),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await pickPhoto(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            Future<void> toggleSpeech() async {
              if (!_speechReady) {
                await _initSpeech();
              }

              if (!_speechReady) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Speech recognition is not available on this device.",
                    ),
                  ),
                );
                return;
              }

              if (listening) {
                await _speech.stop();

                setDialogState(() {
                  listening = false;
                });

                return;
              }

              setDialogState(() {
                listening = true;
              });

              await _speech.listen(
                localeId: "en_IN",
                listenMode: stt.ListenMode.dictation,
                partialResults: true,
                onResult: (result) {
                  final text = result.recognizedWords.trim();

                  if (text.isNotEmpty) {
                    descriptionController.value =
                        TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(
                        offset: text.length,
                      ),
                    );
                  }

                  if (result.finalResult) {
                    setDialogState(() {
                      listening = false;
                    });
                  }
                },
              );
            }

            Future<void> save() async {
              int? vehicleId = selectedVehicleId;

              // Manual mode: API still requires an EXISTING VehicleId.
              if (manualVehicle) {
                vehicleId = int.tryParse(
                  manualVehicleIdController.text.trim(),
                );

                if (vehicleId == null || vehicleId <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Enter a valid existing Vehicle ID.",
                      ),
                    ),
                  );
                  return;
                }

                if (manualVehicleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter vehicle registration number."),
                    ),
                  );
                  return;
                }
              }

              if (vehicleId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select vehicle."),
                  ),
                );
                return;
              }

              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter description."),
                  ),
                );
                return;
              }

              try {
                if (listening) {
                  await _speech.stop();
                  setDialogState(() {
                    listening = false;
                  });
                }

                setDialogState(() {
                  saving = true;
                });

                int? attachmentId;

                // Photo is optional.
                if (selectedPhoto != null) {
                  attachmentId = await _uploadPhoto(selectedPhoto!);
                }

                final result = await _saveAccidentApi(
                  vehicleId: vehicleId!,
                  captured: captured,
                  description: descriptionController.text.trim(),
                  attachmentId: attachmentId,
                );

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                await _loadAccidents();

                if (!mounted) return;

                final accidentId = result["accidentId"];

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      accidentId == null
                          ? "Accident saved successfully."
                          : "Accident #$accidentId saved successfully.",
                    ),
                  ),
                );
              } catch (e) {
                debugPrint("ACCIDENT SAVE ERROR: $e");

                if (!context.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Accident save failed: $e"),
                  ),
                );
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(14),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ======================================================
                      // HEADER
                      // ======================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          10,
                          12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Add Accident",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff182235),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                    },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // ======================================================
                      // FORM
                      // ======================================================
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Vehicle",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff52627A),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Searchable vehicle list.
                            if (!manualVehicle)
                              InkWell(
                                onTap: saving
                                    ? null
                                    : () async {
                                        final vehicle =
                                            await _searchAndSelectVehicle(context);

                                        if (vehicle == null) return;

                                        final id = _extractVehicleId(vehicle);

                                        if (id == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Invalid Vehicle ID."),
                                            ),
                                          );
                                          return;
                                        }

                                        setDialogState(() {
                                          selectedVehicleId = id;
                                        });
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xffD9E2EF),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_car_outlined,
                                        color: Color(0xff52627A),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: selectedVehicleId == null
                                            ? const Text(
                                                "Search and select vehicle",
                                                style: TextStyle(color: Colors.grey),
                                              )
                                            : Builder(
                                                builder: (context) {
                                                  Map<String, dynamic>? selectedVehicle;

                                                  for (final vehicle in _vehicles) {
                                                    if (_extractVehicleId(vehicle) ==
                                                        selectedVehicleId) {
                                                      selectedVehicle = vehicle;
                                                      break;
                                                    }
                                                  }

                                                  return Text(
                                                    selectedVehicle == null
                                                        ? "Selected vehicle"
                                                        : _vehicleLabel(selectedVehicle!),
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                      const Icon(
                                        Icons.search,
                                        color: Color(0xff52627A),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              TextField(
                                controller: manualVehicleController,
                                enabled: !saving,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: "RJ18SS2800",
                                  labelText: "Vehicle Registration No",
                                  prefixIcon: const Icon(
                                    Icons.directions_car_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: manualVehicleIdController,
                                enabled: !saving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Example: 1",
                                  labelText: "Existing Vehicle ID",
                                  prefixIcon: const Icon(Icons.tag),
                                  helperText:
                                      "Vehicle ID must already exist in VehicleMaster.",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],

                            if (!manualVehicle &&
                                _vehicleLoadError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _vehicleLoadError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            TextButton.icon(
                              onPressed: saving
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        manualVehicle = !manualVehicle;
                                        selectedVehicleId = null;
                                      });
                                    },
                              icon: Icon(
                                manualVehicle
                                    ? Icons.list_alt
                                    : Icons.edit_outlined,
                              ),
                              label: Text(
                                manualVehicle
                                    ? "Use vehicle list"
                                    : "Enter vehicle manually",
                              ),
                            ),

                            const SizedBox(height: 8),

                            // =================================================
                            // DATE & TIME
                            // =================================================
                            const Text(
                              "Captured Date & Time",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff52627A),
                              ),
                            ),

                            const SizedBox(height: 6),

                            InkWell(
                              onTap: saving
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: captured,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );

                                      if (date == null) return;
                                      if (!context.mounted) return;

                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            TimeOfDay.fromDateTime(captured),
                                      );

                                      if (time == null) return;

                                      setDialogState(() {
                                        captured = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          time.hour,
                                          time.minute,
                                        );
                                      });
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xffD9E2EF),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          "dd-MM-yyyy hh:mm a",
                                        ).format(captured),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_month),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // =================================================
                            // DESCRIPTION
                            // =================================================
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Description",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff52627A),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: saving ? null : toggleSpeech,
                                  icon: Icon(
                                    listening
                                        ? Icons.mic
                                        : Icons.mic_none,
                                    size: 18,
                                    color: listening
                                        ? Colors.red
                                        : const Color(0xff52627A),
                                  ),
                                  label: Text(
                                    listening ? "Listening..." : "Speak",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: listening
                                          ? Colors.red
                                          : const Color(0xff52627A),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    side: BorderSide(
                                      color: listening
                                          ? Colors.red.shade200
                                          : const Color(0xffD9E2EF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            TextField(
                              controller: descriptionController,
                              enabled: !saving,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: listening
                                    ? "Speak now..."
                                    : "Speak or type what happened...",
                                suffixIcon: listening
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.graphic_eq,
                                          color: Colors.red,
                                        ),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xffD9E2EF),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // =================================================
                            // PHOTO
                            // =================================================
                            const Text(
                              "Photo",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff52627A),
                              ),
                            ),

                            const SizedBox(height: 6),

                            InkWell(
                              onTap: saving ? null : choosePhoto,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xffD9E2EF),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: selectedPhoto == null
                                    ? const Row(
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            color: Color(0xff52627A),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Choose photo from camera or gallery",
                                            ),
                                          ),
                                          Icon(Icons.chevron_right),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: kIsWeb
                                                ? FutureBuilder<Uint8List>(
                                                    future: selectedPhoto!
                                                        .readAsBytes(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (!snapshot.hasData) {
                                                        return const SizedBox(
                                                          width: 56,
                                                          height: 56,
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      }

                                                      return Image.memory(
                                                        snapshot.data!,
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.file(
                                                    File(selectedPhoto!.path),
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              selectedPhoto!.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: saving
                                                ? null
                                                : () {
                                                    setDialogState(() {
                                                      selectedPhoto = null;
                                                    });
                                                  },
                                            icon: const Icon(Icons.close),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // ======================================================
                      // FOOTER
                      // ======================================================
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                    },
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: saving ? null : save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2458A6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Save",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    manualVehicleIdController.dispose();
    manualVehicleController.dispose();
    descriptionController.dispose();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final list = filteredAccidents;

    return Scaffold(
      backgroundColor: const Color(0xffEEF2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        title: const Text(
          "Report Accident",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xffEEF2F7),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;

                final search = TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search vehicle or accident...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );

                final addButton = ElevatedButton.icon(
                  onPressed: _addAccident,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Accident",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2458A6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    children: [
                      search,
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: addButton,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 10),
                    addButton,
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: _loadingAccidents
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : list.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadAccidents,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.car_crash_outlined,
                                    size: 60,
                                    color: Color(0xff9AA9BD),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "No Accident Found",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff52627A),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Add a new accident to get started.",
                                    style: TextStyle(
                                      color: Color(0xff8FA2BF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAccidents,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];

                            final registration =
                                (item["RegistrationNo"] ??
                                        item["vehicle"] ??
                                        item["registrationNo"] ??
                                        "-")
                                    .toString();

                            final model =
                                (item["Model"] ?? item["model"] ?? "")
                                    .toString();

                            final description =
                                (item["Description"] ??
                                        item["description"] ??
                                        "-")
                                    .toString();

                            final capturedAt =
                                item["CapturedAt"] ?? item["date"];

                            final accidentId =
                                item["AccidentId"] ??
                                    item["accidentId"];

                            final photoPath =
                                (item["PhotoPath"] ?? "").toString();

                            // Server returns PhotoPath as a root-relative
                            // path ("/uploads/xxx.jpg") — baseUrl already
                            // ends in "/api", so strip that to get the host
                            // the file actually lives under.
                            final photoUrl = photoPath.isEmpty
                                ? null
                                : baseUrl.replaceFirst(
                                      RegExp(r'/api/?$'),
                                      '',
                                    ) +
                                    photoPath;

                            final locationName = (item["LocationName"] ??
                                    item["CityName"] ??
                                    "")
                                .toString()
                                .trim();

                            final reportedBy =
                                (item["ReportedByName"] ?? "")
                                    .toString()
                                    .trim();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.car_crash,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model.isEmpty
                                                ? registration
                                                : "$registration • $model",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (accidentId != null)
                                            Text(
                                              "Accident ID: $accidentId",
                                              style: const TextStyle(
                                                color: Color(0xff6B7A90),
                                                fontSize: 13,
                                              ),
                                            ),
                                          Text(
                                            "Captured: "
                                            "${_formatCapturedDate(capturedAt)}",
                                            style: const TextStyle(
                                              color: Color(0xff6B7A90),
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (locationName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color: Color(0xff6B7A90),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      locationName,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xff6B7A90),
                                                        fontSize: 13,
                                                      ),
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (reportedBy.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person_outline,
                                                    size: 14,
                                                    color: Color(0xff6B7A90),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Reported by $reportedBy",
                                                    style: const TextStyle(
                                                      color:
                                                          Color(0xff6B7A90),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (photoUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  photoUrl,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const Icon(
                                                    Icons
                                                        .broken_image_outlined,
                                                    color: Colors.white,
                                                    size: 48,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              photoUrl,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons
                                                      .broken_image_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              loadingBuilder: (
                                                _,
                                                child,
                                                progress,
                                              ) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: 56,
                                                  height: 56,
                                                  color:
                                                      Colors.grey.shade100,
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
