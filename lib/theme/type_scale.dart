import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../utils/platform_detector.dart';

/// One text role's size on each form factor. A null size keeps whatever the
/// text style the role is applied to already has.
@immutable
class TypeSize {
  const TypeSize({this.regular, this.phone, this.tv});

  /// Size on desktop, and on phones and tablets when [phone] is null.
  final double? regular;
  final double? phone;

  /// Size on TV; null falls back to [regular]. Roles drawn at a 1080p size
  /// and scaled with the screen state that here.
  final double? tv;

  /// The size on TV, [tv] or [regular].
  double? get tvSize => tv ?? regular;

  /// The size to draw: [tvSize] when [isTv], otherwise [phone] on phones and
  /// tablets and [regular] elsewhere.
  double? resolve(BuildContext context, {required bool isTv}) {
    if (isTv) return tvSize;
    final phone = this.phone;
    if (phone != null && PlatformDetector.isMobile(context)) return phone;
    return regular;
  }

  /// [resolve] for the app's current TV mode.
  double? sizeIn(BuildContext context) => resolve(context, isTv: PlatformDetector.isTV());

  static TypeSize lerp(TypeSize a, TypeSize b, double t) {
    double? d(double? x, double? y) => x == null || y == null ? (t < 0.5 ? x : y) : lerpDouble(x, y, t);
    return TypeSize(regular: d(a.regular, b.regular), phone: d(a.phone, b.phone), tv: d(a.tv, b.tv));
  }

  @override
  bool operator ==(Object other) =>
      other is TypeSize && other.regular == regular && other.phone == phone && other.tv == tv;

  @override
  int get hashCode => Object.hash(regular, phone, tv);
}

/// Text sizes of the app's browse, detail and navigation surfaces, plus an
/// optional brand font.
///
/// Read through [TypeScale.of], which falls back to [fallback] when a theme
/// carries none.
@immutable
class TypeScale extends ThemeExtension<TypeScale> {
  const TypeScale({
    this.fontFamily,
    this.heroTitle = const TypeSize(tv: 52),
    this.heroMeta = const TypeSize(regular: 14, tv: 18),
    this.detailTitle = const TypeSize(tv: 56),
    this.detailSubtitle = const TypeSize(tv: 24),
    this.detailMeta = const TypeSize(tv: 18),
    this.detailSummary = const TypeSize(tv: 18),
    this.detailChip = const TypeSize(regular: 13, tv: 16),
    this.sectionHeader = const TypeSize(tv: 28),
    this.shelfHeader = const TypeSize(tv: 26),
    this.shelfCount = const TypeSize(tv: 17),
    this.shelfAction = const TypeSize(tv: 16),
    this.railHeader = const TypeSize(tv: 18),
    this.railServer = const TypeSize(tv: 15),
    this.railCardTitle = const TypeSize(tv: 13),
    this.railCardCaption = const TypeSize(tv: 11),
    this.railAction = const TypeSize(tv: 13),
    this.cardTitle = const TypeSize(regular: 13),
    this.cardCaption = const TypeSize(regular: 11),
    this.listTitle = const TypeSize(regular: 13),
    this.listSubtitle = const TypeSize(regular: 11),
    this.listMeta = const TypeSize(regular: 10),
    this.labelBadge = const TypeSize(regular: 9),
    this.countBadge = const TypeSize(regular: 10),
    this.navLabel = const TypeSize(regular: 14),
    this.navCaption = const TypeSize(regular: 11),
    this.navSection = const TypeSize(regular: 11),
    this.navNote = const TypeSize(regular: 12),
    this.navLibrary = const TypeSize(regular: 13),
    this.navLibraryServer = const TypeSize(regular: 9),
  });

  /// The shared default sizes, in the platform font.
  static const fallback = TypeScale();

  /// The theme's [TypeScale], or [fallback] when it carries none.
  static TypeScale of(BuildContext context) => Theme.of(context).extension<TypeScale>() ?? fallback;

  /// Font family of the whole theme; null keeps the platform font.
  final String? fontFamily;

  /// Title of the home hero when it has no logo; elsewhere `displaySmall`.
  final TypeSize heroTitle;

  /// Rating, year and progress lines under the home hero title.
  final TypeSize heroMeta;

  /// TV detail hero title at 1080p, scaled with the screen. Elsewhere the
  /// title is sized from its logo box.
  final TypeSize detailTitle;

  /// TV detail hero subtitle (the episode or tagline line) at 1080p.
  final TypeSize detailSubtitle;

  /// TV detail hero metadata line at 1080p.
  final TypeSize detailMeta;

  /// TV detail hero summary at 1080p; a short screen draws it at 90%.
  final TypeSize detailSummary;

  /// Metadata and rating chips on the detail hero.
  final TypeSize detailChip;

  /// Section headers on the detail page (seasons, cast, extras).
  final TypeSize sectionHeader;

  /// Hub (shelf) header.
  final TypeSize shelfHeader;

  /// Result count beside a hub header.
  final TypeSize shelfCount;

  /// The "View all" tile label at the end of a hub.
  final TypeSize shelfAction;

  /// TV browse rail hub title at 1080p, scaled with the screen.
  final TypeSize railHeader;

  /// Server name beside a TV browse rail hub title at 1080p.
  final TypeSize railServer;

  /// Card title and caption in the TV browse rail at 1080p.
  final TypeSize railCardTitle;

  final TypeSize railCardCaption;

  /// Label of the action tile at the end of a TV row at 1080p.
  final TypeSize railAction;

  /// Title and caption under a poster in grids and hub rows.
  final TypeSize cardTitle;

  final TypeSize cardCaption;

  /// List-view rows at the lowest density; each density step adds to them.
  final TypeSize listTitle;

  final TypeSize listSubtitle;

  final TypeSize listMeta;

  /// Text badges on artwork, and the count badge on the Watch Together button.
  final TypeSize labelBadge;

  final TypeSize countBadge;

  /// Side navigation rail: destination labels, the now-playing track line,
  /// server group labels, notes, library names and their server names.
  final TypeSize navLabel;

  final TypeSize navCaption;

  final TypeSize navSection;

  final TypeSize navNote;

  final TypeSize navLibrary;

  final TypeSize navLibraryServer;

  @override
  TypeScale copyWith({
    String? fontFamily,
    TypeSize? heroTitle,
    TypeSize? heroMeta,
    TypeSize? detailTitle,
    TypeSize? detailSubtitle,
    TypeSize? detailMeta,
    TypeSize? detailSummary,
    TypeSize? detailChip,
    TypeSize? sectionHeader,
    TypeSize? shelfHeader,
    TypeSize? shelfCount,
    TypeSize? shelfAction,
    TypeSize? railHeader,
    TypeSize? railServer,
    TypeSize? railCardTitle,
    TypeSize? railCardCaption,
    TypeSize? railAction,
    TypeSize? cardTitle,
    TypeSize? cardCaption,
    TypeSize? listTitle,
    TypeSize? listSubtitle,
    TypeSize? listMeta,
    TypeSize? labelBadge,
    TypeSize? countBadge,
    TypeSize? navLabel,
    TypeSize? navCaption,
    TypeSize? navSection,
    TypeSize? navNote,
    TypeSize? navLibrary,
    TypeSize? navLibraryServer,
  }) => TypeScale(
    fontFamily: fontFamily ?? this.fontFamily,
    heroTitle: heroTitle ?? this.heroTitle,
    heroMeta: heroMeta ?? this.heroMeta,
    detailTitle: detailTitle ?? this.detailTitle,
    detailSubtitle: detailSubtitle ?? this.detailSubtitle,
    detailMeta: detailMeta ?? this.detailMeta,
    detailSummary: detailSummary ?? this.detailSummary,
    detailChip: detailChip ?? this.detailChip,
    sectionHeader: sectionHeader ?? this.sectionHeader,
    shelfHeader: shelfHeader ?? this.shelfHeader,
    shelfCount: shelfCount ?? this.shelfCount,
    shelfAction: shelfAction ?? this.shelfAction,
    railHeader: railHeader ?? this.railHeader,
    railServer: railServer ?? this.railServer,
    railCardTitle: railCardTitle ?? this.railCardTitle,
    railCardCaption: railCardCaption ?? this.railCardCaption,
    railAction: railAction ?? this.railAction,
    cardTitle: cardTitle ?? this.cardTitle,
    cardCaption: cardCaption ?? this.cardCaption,
    listTitle: listTitle ?? this.listTitle,
    listSubtitle: listSubtitle ?? this.listSubtitle,
    listMeta: listMeta ?? this.listMeta,
    labelBadge: labelBadge ?? this.labelBadge,
    countBadge: countBadge ?? this.countBadge,
    navLabel: navLabel ?? this.navLabel,
    navCaption: navCaption ?? this.navCaption,
    navSection: navSection ?? this.navSection,
    navNote: navNote ?? this.navNote,
    navLibrary: navLibrary ?? this.navLibrary,
    navLibraryServer: navLibraryServer ?? this.navLibraryServer,
  );

  /// Sizes interpolate; the font family switches at the midpoint.
  @override
  TypeScale lerp(covariant TypeScale? other, double t) {
    if (other == null) return this;
    return TypeScale(
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      heroTitle: TypeSize.lerp(heroTitle, other.heroTitle, t),
      heroMeta: TypeSize.lerp(heroMeta, other.heroMeta, t),
      detailTitle: TypeSize.lerp(detailTitle, other.detailTitle, t),
      detailSubtitle: TypeSize.lerp(detailSubtitle, other.detailSubtitle, t),
      detailMeta: TypeSize.lerp(detailMeta, other.detailMeta, t),
      detailSummary: TypeSize.lerp(detailSummary, other.detailSummary, t),
      detailChip: TypeSize.lerp(detailChip, other.detailChip, t),
      sectionHeader: TypeSize.lerp(sectionHeader, other.sectionHeader, t),
      shelfHeader: TypeSize.lerp(shelfHeader, other.shelfHeader, t),
      shelfCount: TypeSize.lerp(shelfCount, other.shelfCount, t),
      shelfAction: TypeSize.lerp(shelfAction, other.shelfAction, t),
      railHeader: TypeSize.lerp(railHeader, other.railHeader, t),
      railServer: TypeSize.lerp(railServer, other.railServer, t),
      railCardTitle: TypeSize.lerp(railCardTitle, other.railCardTitle, t),
      railCardCaption: TypeSize.lerp(railCardCaption, other.railCardCaption, t),
      railAction: TypeSize.lerp(railAction, other.railAction, t),
      cardTitle: TypeSize.lerp(cardTitle, other.cardTitle, t),
      cardCaption: TypeSize.lerp(cardCaption, other.cardCaption, t),
      listTitle: TypeSize.lerp(listTitle, other.listTitle, t),
      listSubtitle: TypeSize.lerp(listSubtitle, other.listSubtitle, t),
      listMeta: TypeSize.lerp(listMeta, other.listMeta, t),
      labelBadge: TypeSize.lerp(labelBadge, other.labelBadge, t),
      countBadge: TypeSize.lerp(countBadge, other.countBadge, t),
      navLabel: TypeSize.lerp(navLabel, other.navLabel, t),
      navCaption: TypeSize.lerp(navCaption, other.navCaption, t),
      navSection: TypeSize.lerp(navSection, other.navSection, t),
      navNote: TypeSize.lerp(navNote, other.navNote, t),
      navLibrary: TypeSize.lerp(navLibrary, other.navLibrary, t),
      navLibraryServer: TypeSize.lerp(navLibraryServer, other.navLibraryServer, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TypeScale &&
      other.fontFamily == fontFamily &&
      other.heroTitle == heroTitle &&
      other.heroMeta == heroMeta &&
      other.detailTitle == detailTitle &&
      other.detailSubtitle == detailSubtitle &&
      other.detailMeta == detailMeta &&
      other.detailSummary == detailSummary &&
      other.detailChip == detailChip &&
      other.sectionHeader == sectionHeader &&
      other.shelfHeader == shelfHeader &&
      other.shelfCount == shelfCount &&
      other.shelfAction == shelfAction &&
      other.railHeader == railHeader &&
      other.railServer == railServer &&
      other.railCardTitle == railCardTitle &&
      other.railCardCaption == railCardCaption &&
      other.railAction == railAction &&
      other.cardTitle == cardTitle &&
      other.cardCaption == cardCaption &&
      other.listTitle == listTitle &&
      other.listSubtitle == listSubtitle &&
      other.listMeta == listMeta &&
      other.labelBadge == labelBadge &&
      other.countBadge == countBadge &&
      other.navLabel == navLabel &&
      other.navCaption == navCaption &&
      other.navSection == navSection &&
      other.navNote == navNote &&
      other.navLibrary == navLibrary &&
      other.navLibraryServer == navLibraryServer;

  @override
  int get hashCode => Object.hashAll([
    fontFamily,
    heroTitle,
    heroMeta,
    detailTitle,
    detailSubtitle,
    detailMeta,
    detailSummary,
    detailChip,
    sectionHeader,
    shelfHeader,
    shelfCount,
    shelfAction,
    railHeader,
    railServer,
    railCardTitle,
    railCardCaption,
    railAction,
    cardTitle,
    cardCaption,
    listTitle,
    listSubtitle,
    listMeta,
    labelBadge,
    countBadge,
    navLabel,
    navCaption,
    navSection,
    navNote,
    navLibrary,
    navLibraryServer,
  ]);
}
