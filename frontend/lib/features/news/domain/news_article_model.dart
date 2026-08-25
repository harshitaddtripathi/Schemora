import 'package:flutter/material.dart';

class MultilingualText {
  final String en;
  final String hi;
  final String mr;
  final String gu;
  final String bn;
  final String ta;
  final String te;
  final String kn;
  final String ml;
  final String pa;
  final String or;
  final String as;
  final String ur;
  final String bho;
  final String sa;
  final String mai;

  const MultilingualText({
    required this.en,
    required this.hi,
    this.mr = '',
    this.gu = '',
    this.bn = '',
    this.ta = '',
    this.te = '',
    this.kn = '',
    this.ml = '',
    this.pa = '',
    this.or = '',
    this.as = '',
    this.ur = '',
    this.bho = '',
    this.sa = '',
    this.mai = '',
  });

  String getForLanguage(String langCode) {
    switch (langCode) {
      case 'hi':
        return hi.isNotEmpty ? hi : en;
      case 'mr':
        return mr.isNotEmpty ? mr : (hi.isNotEmpty ? hi : en);
      case 'gu':
        return gu.isNotEmpty ? gu : (hi.isNotEmpty ? hi : en);
      case 'bn':
        return bn.isNotEmpty ? bn : (hi.isNotEmpty ? hi : en);
      case 'ta':
        return ta.isNotEmpty ? ta : en;
      case 'te':
        return te.isNotEmpty ? te : en;
      case 'kn':
        return kn.isNotEmpty ? kn : en;
      case 'ml':
        return ml.isNotEmpty ? ml : en;
      case 'pa':
        return pa.isNotEmpty ? pa : (hi.isNotEmpty ? hi : en);
      case 'or':
        return or.isNotEmpty ? or : (hi.isNotEmpty ? hi : en);
      case 'as':
        return as.isNotEmpty ? as : (bn.isNotEmpty ? bn : en);
      case 'ur':
        return ur.isNotEmpty ? ur : en;
      case 'bho':
        return bho.isNotEmpty ? bho : (hi.isNotEmpty ? hi : en);
      case 'sa':
        return sa.isNotEmpty ? sa : (hi.isNotEmpty ? hi : en);
      case 'mai':
        return mai.isNotEmpty ? mai : (hi.isNotEmpty ? hi : en);
      case 'en':
      default:
        return en;
    }
  }
}

class NewsArticleModel {
  final String id;
  final MultilingualText title;
  final MultilingualText category;
  final Color categoryColor;
  final String timeAgo;
  final String source;
  final MultilingualText summary;
  final MultilingualText fullContent;
  final List<MultilingualText> keyHighlights;
  final String imagePath;
  final IconData icon;

  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.timeAgo,
    required this.source,
    required this.summary,
    required this.fullContent,
    required this.keyHighlights,
    required this.imagePath,
    required this.icon,
  });

  String getTitle(String langCode) => title.getForLanguage(langCode);
  String getCategory(String langCode) => category.getForLanguage(langCode);
  String getSummary(String langCode) => summary.getForLanguage(langCode);
  String getFullContent(String langCode) => fullContent.getForLanguage(langCode);
  List<String> getHighlights(String langCode) =>
      keyHighlights.map((h) => h.getForLanguage(langCode)).toList();
}
