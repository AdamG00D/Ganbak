/// كلمات "مين الجاسوس": فئة ← كلمات (عربي | إنجليزي).
/// الكلمة بتتبعت بالاتنين عشان كل لاعب يشوفها بلغة تطبيقه.
class SpyWords {
  SpyWords._();

  static const categories = <String, List<String>>{
    'أكلات|Food': [
      'كشري|Koshari', 'فول|Fava beans', 'طعمية|Falafel', 'محشي|Stuffed vegetables', 'ملوخية|Molokhia',
      'بيتزا|Pizza', 'شاورما|Shawarma', 'فطير|Feteer', 'كبدة|Liver sandwich', 'بسبوسة|Basbousa',
      'كنافة|Kunafa', 'أرز باللبن|Rice pudding', 'حواوشي|Hawawshi', 'سمك مشوي|Grilled fish', 'برجر|Burger',
    ],
    'أماكن|Places': [
      'المطار|Airport', 'المستشفى|Hospital', 'المدرسة|School', 'الشاطئ|Beach', 'السينما|Cinema',
      'المترو|Metro', 'السوبر ماركت|Supermarket', 'الجيم|Gym', 'المكتبة|Library', 'الفرح|Wedding',
      'الملعب|Stadium', 'الصيدلية|Pharmacy', 'القهوة|Café', 'الأهرامات|The pyramids', 'حديقة الحيوان|Zoo',
    ],
    'حيوانات|Animals': [
      'قطة|Cat', 'كلب|Dog', 'جمل|Camel', 'أسد|Lion', 'زرافة|Giraffe', 'فيل|Elephant', 'حمار|Donkey',
      'تمساح|Crocodile', 'بطريق|Penguin', 'قرد|Monkey', 'حصان|Horse', 'بطة|Duck', 'ثعبان|Snake',
      'دولفين|Dolphin', 'نسر|Eagle',
    ],
    'مهن|Jobs': [
      'دكتور|Doctor', 'مدرس|Teacher', 'سواق|Driver', 'طباخ|Chef', 'مهندس|Engineer', 'نجار|Carpenter',
      'ظابط|Police officer', 'طيار|Pilot', 'حلاق|Barber', 'محامي|Lawyer', 'مصور|Photographer',
      'صيدلي|Pharmacist', 'كهربائي|Electrician', 'مذيع|TV presenter', 'لاعب كورة|Footballer',
    ],
    'حاجات في البيت|Things at home': [
      'تلاجة|Fridge', 'غسالة|Washing machine', 'سرير|Bed', 'مروحة|Fan', 'تليفزيون|TV', 'مراية|Mirror',
      'كنبة|Sofa', 'بوتاجاز|Stove', 'مكنسة|Broom', 'ستارة|Curtain', 'دولاب|Wardrobe', 'مخدة|Pillow',
      'سجادة|Carpet', 'ساعة حيطة|Wall clock', 'غلاية|Kettle',
    ],
    'رياضة|Sports': [
      'كورة قدم|Football', 'سباحة|Swimming', 'تنس|Tennis', 'كاراتيه|Karate', 'سلة|Basketball',
      'جري|Running', 'ملاكمة|Boxing', 'بينج بونج|Ping-pong', 'شطرنج|Chess', 'عجل|Cycling', 'يد|Handball',
      'كرة طايرة|Volleyball', 'غطس|Diving', 'رفع أتقال|Weightlifting', 'جمباز|Gymnastics',
    ],
    'مواصلات|Transport': [
      'توك توك|Tuk-tuk', 'ميكروباص|Microbus', 'تاكسي|Taxi', 'قطر|Train', 'طيارة|Plane', 'مركب|Boat',
      'عجلة|Bicycle', 'موتوسيكل|Motorbike', 'أتوبيس|Bus', 'عربية كارو|Donkey cart', 'تروماي|Tram',
      'سكوتر|Scooter', 'صاروخ|Rocket', 'معدية|Ferry', 'ونش|Tow truck',
    ],
    'مناسبات|Occasions': [
      'رمضان|Ramadan', 'العيد|Eid', 'عيد ميلاد|Birthday', 'فرح|Wedding', 'خطوبة|Engagement',
      'شم النسيم|Sham El-Nessim', 'التخرج|Graduation', 'رأس السنة|New Year', 'سبوع|Baby\'s 7th-day party',
      'نتيجة الثانوية|Exam results day', 'المولد|Mawlid', 'رحلة المدرسة|School trip', 'سحور|Suhoor',
      'ماتش نهائي|Cup final', 'حنة|Henna night',
    ],
  };

  static List<String> get categoryKeys => categories.keys.toList();

  /// (عربي، إنجليزي) من "عربي|إنجليزي".
  static (String, String) split(String pair) {
    final i = pair.indexOf('|');
    return i < 0 ? (pair, pair) : (pair.substring(0, i), pair.substring(i + 1));
  }
}
