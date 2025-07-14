import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const String _keyPrefs = 'encryption_key';
  static const String _ivPrefs = 'encryption_iv';
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    _initializeEncryption();
  }

  Future<void> _initializeEncryption() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Récupérer ou générer la clé de chiffrement
    String? keyString = prefs.getString(_keyPrefs);
    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = base64.encode(key.bytes);
      await prefs.setString(_keyPrefs, keyString);
    }
    _key = encrypt.Key(base64.decode(keyString));

    // Récupérer ou générer le vecteur d'initialisation
    String? ivString = prefs.getString(_ivPrefs);
    if (ivString == null) {
      final iv = encrypt.IV.fromSecureRandom(16);
      ivString = base64.encode(iv.bytes);
      await prefs.setString(_ivPrefs, ivString);
    }
    _iv = encrypt.IV(base64.decode(ivString));

    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    final encrypted = _encrypter.encryptBytes(fileBytes, iv: _iv);
    return Uint8List.fromList(encrypted.bytes);
  }

  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decrypted = _encrypter.decryptBytes(encrypted, iv: _iv);
    return Uint8List.fromList(decrypted);
  }

  String hashFile(Uint8List fileBytes) {
    final hash = sha256.convert(fileBytes);
    return hash.toString();
  }

  bool verifyFileHash(Uint8List fileBytes, String expectedHash) {
    final hash = sha256.convert(fileBytes);
    return hash.toString() == expectedHash;
  }
} 