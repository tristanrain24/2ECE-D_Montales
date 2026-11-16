import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

// ───────── catalog ─────────

abstract class CatalogSource {
  Future<Catalog> load();
}

/// The catalog that ships inside the app. Swap for a remote source to
/// publish monthly re-scores without an app update.
class BundledCatalogSource implements CatalogSource {
  const BundledCatalogSource();
  @override
  Future<Catalog> load() async =>
      Catalog.fromJson(await rootBundle.loadString('assets/data/catalog.json'));
}

// ───────── storage ─────────

abstract class Storage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class PrefsStorage implements Storage {
  static const _key = 'vertex.state.v1';
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);
  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(_key, value);
  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

class MemoryStorage implements Storage {
  MemoryStorage([this.value]);
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String v) async => value = v;
  @override
  Future<void> clear() async => value = null;
}

// ───────── payments ─────────

enum PayMethod {
  applePay('Apple Pay'),
  googlePay('Google Pay'),
  card('Card'),
  payPal('PayPal');

  const PayMethod(this.label);
  final String label;
}

class PaymentResult {
  const PaymentResult.ok(this.reference) : error = null;
  const PaymentResult.failed(this.error) : reference = null;
  final String? reference;
  final String? error;
  bool get ok => error == null;
}

abstract class PaymentGateway {
  /// True when no money moves. The UI says so wherever a charge is shown.
  bool get isDemo;
  Future<PaymentResult> charge({
    required int amountCents,
    required PayMethod method,
    required String description,
  });
}

/// Stands in for a real processor. It never takes payment details and
/// never charges anyone; it only lets the purchase flow complete.
class DemoPaymentGateway implements PaymentGateway {
  DemoPaymentGateway({this.delay = const Duration(milliseconds: 1400)});
  final Duration delay;
  final _rng = Random();

  @override
  bool get isDemo => true;

  @override
  Future<PaymentResult> charge({
    required int amountCents,
    required PayMethod method,
    required String description,
  }) async {
    await Future<void>.delayed(delay);
    // 0x7fffffff keeps the bound valid on the web, where ints are doubles.
    return PaymentResult.ok(
      'demo_${_rng.nextInt(0x7fffffff).toRadixString(16)}',
    );
  }
}

// ───────── student verification ─────────

class VerificationException implements Exception {
  const VerificationException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class StudentVerifier {
  bool get isDemo;

  /// Sends a one-time code to [email]. Throws [VerificationException] if the
  /// address is not an academic one.
  Future<void> sendCode(String email);

  /// Confirms the code and returns the verified status.
  Future<StudentStatus> confirm(String email, String code);

  /// In demo mode there is no mail server, so the code is shown in the app.
  String? demoCodeFor(String email);
}

final _emailRe = RegExp(r'^[^\s@]+@([a-z0-9-]+\.)+[a-z]{2,}$');

/// Accepts `.edu`, `.edu.xx` and `.ac.xx` hosts (and their subdomains).
bool isAcademicEmail(String email) {
  final e = email.trim().toLowerCase();
  if (!_emailRe.hasMatch(e)) return false;
  final labels = e.split('@').last.split('.');
  final n = labels.length;
  if (labels.last == 'edu') return true;
  return n >= 3 && (labels[n - 2] == 'edu' || labels[n - 2] == 'ac');
}

const _institutions = {
  'mit.edu': 'Massachusetts Institute of Technology',
  'stanford.edu': 'Stanford University',
  'harvard.edu': 'Harvard University',
  'berkeley.edu': 'University of California, Berkeley',
  'ox.ac.uk': 'University of Oxford',
  'cam.ac.uk': 'University of Cambridge',
  'up.edu.ph': 'University of the Philippines',
  'ust.edu.ph': 'University of Santo Tomas',
  'dlsu.edu.ph': 'De La Salle University',
  'ateneo.edu': 'Ateneo de Manila University',
  'nus.edu.sg': 'National University of Singapore',
};

String institutionFor(String email) {
  final host = email.trim().toLowerCase().split('@').last;
  for (final e in _institutions.entries) {
    if (host == e.key || host.endsWith('.${e.key}')) return e.value;
  }
  return host;
}

class DemoStudentVerifier implements StudentVerifier {
  DemoStudentVerifier({
    this.delay = const Duration(milliseconds: 700),
    Random? random,
    DateTime Function()? clock,
  }) : _rng = random ?? Random(),
       _now = clock ?? DateTime.now;
  final Duration delay;
  final Random _rng;
  final DateTime Function() _now;
  final _codes = <String, String>{};

  @override
  bool get isDemo => true;

  @override
  Future<void> sendCode(String email) async {
    final e = email.trim().toLowerCase();
    if (!isAcademicEmail(e)) {
      throw const VerificationException(
        'Use a school address — one ending in .edu, .edu.xx or .ac.xx.',
      );
    }
    await Future<void>.delayed(delay);
    _codes[e] = (_rng.nextInt(900000) + 100000).toString();
  }

  @override
  String? demoCodeFor(String email) => _codes[email.trim().toLowerCase()];

  @override
  Future<StudentStatus> confirm(String email, String code) async {
    final e = email.trim().toLowerCase();
    await Future<void>.delayed(delay);
    final want = _codes[e];
    if (want == null) {
      throw const VerificationException('Send a code first.');
    }
    if (code.trim() != want) {
      throw const VerificationException(
        'That code doesn’t match. Check it and try again.',
      );
    }
    _codes.remove(e);
    return StudentStatus(
      email: e,
      institution: institutionFor(e),
      verifiedAt: _now(),
    );
  }
}

String newLicenceKey(Tool tool, [Random? random]) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = random ?? Random.secure();
  String block() =>
      List.generate(4, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  final tag = tool.name
      .toUpperCase()
      .replaceAll(RegExp('[^A-Z]'), '')
      .padRight(4, 'X')
      .substring(0, 4);
  return 'VX-$tag-${block()}-${block()}';
}
