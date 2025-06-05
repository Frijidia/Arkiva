import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

import '../services/auth_service.dart';
import '../services/auth_state_service.dart';
import '../models/entreprise.dart';

class CreateEntrepriseScreen extends StatefulWidget {
  const CreateEntrepriseScreen({Key? key}) : super(key: key);

  @override
  _CreateEntrepriseScreenState createState() => _CreateEntrepriseScreenState();
}

class _CreateEntrepriseScreenState extends State<CreateEntrepriseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  // Champs du formulaire d'entreprise
  final _nomController = TextEditingController();
  final _entrepriseEmailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  Uint8List? _logoBytes;

  @override
  void dispose() {
    _nomController.dispose();
    _entrepriseEmailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _logoBytes = result.files.single.bytes;
      });
    }
  }

  // ... (rest of the existing code)
} 