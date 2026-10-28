import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic helper for secure PBKDF2-HMAC-SHA256 local password hashing.
class PasswordHasher {
  PasswordHasher._();

  /// Generates a cryptographically secure 16-byte random salt.
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  /// Derives a PBKDF2-HMAC-SHA256 verifier hash from a plaintext password and base64 salt.
  /// Uses OWASP recommended 600,000 iterations for local key derivation protection.
  static String deriveHash(
    String password,
    String saltBase64, {
    int iterations = 600000,
    int keyLength = 32,
  }) {
    final saltBytes = base64Decode(saltBase64);
    final passwordBytes = utf8.encode(password);

    final hmac = Hmac(sha256, passwordBytes);
    final numBlocks = (keyLength / 32).ceil();
    final derivedBytes = BytesBuilder();

    for (int block = 1; block <= numBlocks; block++) {
      final blockBytes = BytesBuilder();
      blockBytes.add(saltBytes);
      blockBytes.add([
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]);

      List<int> u = hmac.convert(blockBytes.toBytes()).bytes;
      List<int> result = List<int>.from(u);

      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      derivedBytes.add(result);
    }

    final keyBytes = derivedBytes.toBytes().sublist(0, keyLength);
    return base64Encode(keyBytes);
  }

  /// Compares two verifier hashes in constant time to prevent side-channel timing attacks.
  static bool constantTimeCompare(String hashA, String hashB) {
    if (hashA.length != hashB.length) return false;
    int result = 0;
    for (int i = 0; i < hashA.length; i++) {
      result |= hashA.codeUnitAt(i) ^ hashB.codeUnitAt(i);
    }
    return result == 0;
  }
}
