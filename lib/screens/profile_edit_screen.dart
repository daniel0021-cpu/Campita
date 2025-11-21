import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import 'dart:html' as html; // for web image picking

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _deptController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _dormController = TextEditingController();
  final _roomController = TextEditingController();
  Uint8List? _avatarBytes;
  final PreferencesService _prefs = PreferencesService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _prefs.loadProfileData();
    _nameController.text = data['name'] ?? '';
    _levelController.text = data['level'] ?? '';
    _deptController.text = data['department'] ?? '';
    _studentIdController.text = data['studentId'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _bioController.text = data['bio'] ?? '';
    _dormController.text = data['dorm'] ?? '';
    _roomController.text = data['room'] ?? '';
    final avatarBase64 = data['avatar'];
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        _avatarBytes = Base64Decoder().convert(avatarBase64);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  void _pickImage() {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _avatarBytes = reader.result as Uint8List?;
          });
        });
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final avatarBase64 = _avatarBytes != null ? base64Encode(_avatarBytes!) : null;
    await _prefs.saveProfileData(
      name: _nameController.text.trim(),
      level: _levelController.text.trim(),
      department: _deptController.text.trim(),
      avatarBase64: avatarBase64,
      studentId: _studentIdController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      dorm: _dormController.text.trim(),
      room: _roomController.text.trim(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                          child: _avatarBytes == null ? const Icon(Icons.person, size: 50, color: AppColors.primary) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(26),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _fieldLabel('Full Name *'),
                  _textField(_nameController, 'Enter your full name'),
                  const SizedBox(height: 20),
                  _fieldLabel('Student ID'),
                  _textField(_studentIdController, 'e.g. IGU/2021/0001', required: false),
                  const SizedBox(height: 20),
                  _fieldLabel('Level *'),
                  _textField(_levelController, 'e.g. 300 Level'),
                  const SizedBox(height: 20),
                  _fieldLabel('Department *'),
                  _textField(_deptController, 'e.g. Computer Science'),
                  const SizedBox(height: 20),
                  _fieldLabel('Email Address'),
                  _textField(_emailController, 'your.email@student.edu.ng', required: false, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _fieldLabel('Phone Number'),
                  _textField(_phoneController, '080XXXXXXXX', required: false, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _fieldLabel('Bio'),
                  _textField(_bioController, 'Tell us about yourself...', required: false, maxLines: 3),
                  const SizedBox(height: 20),
                  _fieldLabel('Dormitory'),
                  _textField(_dormController, 'e.g. Hall 1', required: false),
                  const SizedBox(height: 20),
                  _fieldLabel('Room Number'),
                  _textField(_roomController, 'e.g. A204', required: false),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Save Changes', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
      );

  Widget _textField(
    TextEditingController c,
    String hint, {
    bool required = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: c,
      validator: (v) => (required && (v == null || v.trim().isEmpty)) ? 'Required field' : null,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.cardBackground(context),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: maxLines > 1 ? 16 : 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderAdaptive(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderAdaptive(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
