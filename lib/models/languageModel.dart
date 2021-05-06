class Language {
  final int id;
  final String name;
  final String flag; // country flag (shows in UI)
  final String languageCode; // en,ar

  Language(this.id, this.name, this.flag, this.languageCode);

  static List<Language> languageList() {
    return <Language>[
      Language(1, "English", "🇺🇸", "en"),
      Language(2, "العربية", "🇪🇬", "ar"),
    ];
  }
}
