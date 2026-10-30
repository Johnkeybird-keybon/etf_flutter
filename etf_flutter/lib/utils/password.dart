import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String plain) =>
    sha256.convert(utf8.encode(plain)).toString();