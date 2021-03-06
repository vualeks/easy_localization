import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Localization {
  Map<String, dynamic> _sentences;
  Locale _locale;

  Localization._();

  static Localization _instance;
  static Localization get instance =>
      _instance ?? (_instance = Localization._());

  static Future<bool> load(
    Locale locale, {
    String path,
    String loadPath,
    bool useOnlyLangCode,
    bool useDocumentStorage,
  }) async {
    String data;

    var _codeLang = locale.languageCode;
    var _codeCoun = locale.countryCode;

    instance._locale = Locale(_codeLang, _codeCoun);

    var basePath = path != null ? path : loadPath;
    var localePath = '$basePath/$_codeLang';
    localePath += useOnlyLangCode ? '.json' : '-$_codeCoun.json';

    if (path != null) {
      if (useDocumentStorage) {
        File file = File(localePath);
        data = await file.readAsString();
      } else {
        data = await rootBundle.loadString(localePath);
      }
    } else if (loadPath != null) {
      data = await http
          .get(localePath)
          .then((response) => response.body.toString());
    }

    Map<String, dynamic> _result = json.decode(data);

    instance._sentences = new Map();
    _result.forEach((String key, dynamic value) {
      instance._sentences[key] = value;
    });
    return true;
  }

  String tr(String key, {List<String> args, String gender}) {
    String res;
    if (gender != null) {
      res = _gender(key, gender: gender);
    }

    if (res == null) {
      res = this._resolve(key, this._sentences);
    }

    if (args != null) {
      args.forEach((String str) {
        res = res.replaceFirst(RegExp(r'{}'), str);
      });
    }

    return res;
  }

  String plural(String key, dynamic value) {
    final res = Intl.pluralLogic(value,
        zero: this._resolve(key + '.zero', this._sentences),
        one: this._resolve(key + '.one', this._sentences),
        two: this._resolve(key + '.two', this._sentences),
        few: this._resolve(key + '.few', this._sentences),
        many: this._resolve(key + '.many', this._sentences),
        other: this._resolve(key + '.other', this._sentences),
        locale: _locale.languageCode);
    return res.replaceFirst(RegExp(r'{}'), '$value');
  }

  String _gender(String key, {String gender}) {
    final res = Intl.genderLogic(gender,
        female: this._resolve(key + '.female', this._sentences),
        male: this._resolve(key + '.male', this._sentences),
        other: this._resolve(key + '.male', this._sentences),
        locale: _locale.languageCode);
    return res;
  }

  String _resolve(String path, dynamic obj) {
    List<String> keys = path.split('.');

    if (keys.length > 1) {
      for (int index = 0; index <= keys.length; index++) {
        if (obj.containsKey(keys[index]) && obj[keys[index]] is! String) {
          return _resolve(
              keys.sublist(index + 1, keys.length).join('.'), obj[keys[index]]);
        }

        return obj[path] ?? path;
      }
    }

    return obj[path] ?? path;
  }
}
