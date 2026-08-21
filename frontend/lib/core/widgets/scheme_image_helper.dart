class SchemeImageHelper {
  /// Returns a relatable image asset path for any scheme based on title & category.
  static String getSchemeImage({required String title, String? category}) {
    final t = title.toLowerCase();
    final c = (category ?? '').toLowerCase();

    if (t.contains('kisan') ||
        t.contains('fasal') ||
        t.contains('crop') ||
        t.contains('farm') ||
        c.contains('agri')) {
      return 'assets/images/agriculture_card.png';
    } else if (t.contains('scholarship') ||
        t.contains('education') ||
        t.contains('post matric') ||
        t.contains('college') ||
        t.contains('mysy') ||
        c.contains('scholar') ||
        c.contains('edu')) {
      return 'assets/images/scholarship_card.png';
    } else if (t.contains('mudra') ||
        t.contains('loan') ||
        t.contains('msme') ||
        t.contains('business') ||
        t.contains('vendor') ||
        t.contains('svanidhi') ||
        c.contains('entrepreneur') ||
        c.contains('business')) {
      return 'assets/images/business_card.png';
    } else if (t.contains('woman') ||
        t.contains('women') ||
        t.contains('ladki') ||
        t.contains('kanya') ||
        t.contains('lakshmi') ||
        t.contains('matru') ||
        c.contains('women')) {
      return 'assets/images/women_card.png';
    } else if (t.contains('pension') ||
        t.contains('senior') ||
        t.contains('atal') ||
        t.contains('old age') ||
        t.contains('apy') ||
        c.contains('pension') ||
        c.contains('senior')) {
      return 'assets/images/pension_card.png';
    } else if (t.contains('awas') ||
        t.contains('housing') ||
        t.contains('house') ||
        c.contains('housing')) {
      return 'assets/images/housing_card.png';
    } else if (t.contains('ayushman') ||
        t.contains('health') ||
        t.contains('medical') ||
        t.contains('bima') ||
        c.contains('health')) {
      return 'assets/images/health_card.png';
    }
    return 'assets/images/schemora_hero.png';
  }
}
