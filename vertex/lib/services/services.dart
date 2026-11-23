import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';

// ───────── catalog ─────────

/// Where the app downloads updated ratings on launch. Empty (the default)
/// keeps the app fully offline on its bundled ratings, which suits a private
/// project. To turn updates on, publish catalog.json at a URL the app can
/// read and build with `--dart-define=CATALOG_URL=https://…/catalog.json`.
const catalogUrl = String.fromEnvironment('CATALOG_URL');

/// Address of a published web version, used for links shared from the
/// native apps. Empty while the project is private: there is no public site.
const webAppUrl = String.fromEnvironment('WEB_APP_URL');

/// Loads the catalog the app starts with, then looks for a newer one.
///
/// Start-up never waits on the network: the app opens with the last catalog
/// it downloaded (or the copy bundled in the app), and [refresh] fetches the
/// published file afterwards. A download that is missing, malformed or empty
/// is ignored, so a bad edit to the published file cannot break the app.
class CatalogSource {
  CatalogSource({
    this.url = catalogUrl,
    http.Client? client,
    Future<String> Function()? bundled,
    this.cache,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _bundled =
           bundled ?? (() => rootBundle.loadString('assets/data/catalog.json'));

  final String url;
  final http.Client _client;
  final Future<String> Function() _bundled;
  final Storage? cache;
  final Duration timeout;

  /// The cached download if it is still valid, otherwise the bundled copy.
  Future<Catalog> initial() async {
    final cached = await cache?.read();
    if (cached != null) {
      try {
        return Catalog.fromJson(cached);
      } on Object {
        await cache?.clear();
      }
    }
    return Catalog.fromJson(await _bundled());
  }

  /// Downloads the published catalog. Null when it is unreachable or unusable.
  Future<Catalog?> refresh() async {
    if (url.isEmpty) return null;
    try {
      final res = await _client
          .get(Uri.parse(url), headers: const {'Cache-Control': 'no-cache'})
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      final body = res.body;
      final catalog = Catalog.fromJson(body);
      await cache?.write(body);
      return catalog;
    } on Object {
      return null;
    }
  }
}

// ───────── storage ─────────

abstract class Storage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class PrefsStorage implements Storage {
  const PrefsStorage([this.key = 'vertex.state.v1']);
  final String key;
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(key);
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

// ───────── vendor links ─────────

/// Opens a vendor's site. On phones this is an in-app browser sheet;
/// on desktop, the default browser.
abstract class LinkOpener {
  Future<bool> open(Uri uri);
}

class SystemLinkOpener implements LinkOpener {
  const SystemLinkOpener();
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri);
    } on Object {
      return false;
    }
  }
}
