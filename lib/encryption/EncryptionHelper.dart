import 'package:encrypt/encrypt.dart';

class EncryptionHelper{
  static EncryptionHelper _encryptionHelper;
  static var _key;
  static var _iv;
  static var _newKey;
  static void setEncryptionHelper(EncryptionHelper eh, String encryptionKey, String uid){
    _encryptionHelper = eh;
    final newKey = encryptionKey + uid.substring(0,32-encryptionKey.length);
    _newKey = newKey;
    _key = Key.fromBase64(newKey);
    _iv = IV.fromBase64(uid.substring(0,24));
  }

  static String encrypt(String noteToEncrypt){
    final encrypter = Encrypter(AES(_key, mode: AESMode.cfb64));
    final encrypted = encrypter.encrypt(noteToEncrypt, iv: _iv);
    return encrypted.base64.toString();
  }

  static String decrypt(String noteToDecrypt){
    final encrypter = Encrypter(AES(_key, mode: AESMode.cfb64));
    final decrypted = encrypter.decrypt64(noteToDecrypt, iv: _iv);
    return decrypted;
  }
}