/// بنك أسئلة المسابقة. كل سؤال: الفئة، السؤال (عربي|إنجليزي)، والاختيارات — **الأول هو الصح**
/// (اللعبة بتلخبط ترتيبها). عايز تزوّد أسئلة؟ زوّد هنا وخلّي الإجابة الصح أول واحدة.
class QuizQuestion {
  const QuizQuestion(this.category, this.question, this.options);
  final String category;
  final String question;
  final List<String> options;
}

class QuizBank {
  QuizBank._();

  static const categories = ['عامة|General', 'جغرافيا|Geography', 'علوم|Science', 'رياضة|Sports', 'مصر|Egypt'];

  static const all = <QuizQuestion>[
    // ---------------- عامة ----------------
    QuizQuestion('عامة|General', 'كام يوم في السنة الكبيسة؟|How many days are in a leap year?', ['366|366', '365|365', '364|364', '360|360']),
    QuizQuestion('عامة|General', 'كام لون في قوس قزح؟|How many colours are in a rainbow?', ['7|7', '5|5', '6|6', '8|8']),
    QuizQuestion('عامة|General', 'إيه أكبر محيط في العالم؟|What is the largest ocean?', ['الهادي|Pacific', 'الأطلنطي|Atlantic', 'الهندي|Indian', 'المتجمد الشمالي|Arctic']),
    QuizQuestion('عامة|General', 'كام دقيقة في الساعة؟|How many minutes are in an hour?', ['60|60', '100|100', '30|30', '90|90']),
    QuizQuestion('عامة|General', 'العنكبوت عنده كام رجل؟|How many legs does a spider have?', ['8|8', '6|6', '10|10', '4|4']),
    QuizQuestion('عامة|General', 'إيه أسرع حيوان على الأرض؟|What is the fastest land animal?', ['الفهد|Cheetah', 'الأسد|Lion', 'الحصان|Horse', 'الغزال|Gazelle']),
    QuizQuestion('عامة|General', 'كام ضلع في المسدس؟|How many sides does a hexagon have?', ['6|6', '5|5', '8|8', '7|7']),
    QuizQuestion('عامة|General', 'إيه أكبر كوكب في المجموعة الشمسية؟|What is the largest planet in the solar system?', ['المشتري|Jupiter', 'زحل|Saturn', 'الأرض|Earth', 'نبتون|Neptune']),
    QuizQuestion('عامة|General', 'كام سنة في القرن؟|How many years are in a century?', ['100|100', '10|10', '1000|1000', '50|50']),
    QuizQuestion('عامة|General', 'مين رسم الموناليزا؟|Who painted the Mona Lisa?', ['ليوناردو دا فينشي|Leonardo da Vinci', 'بيكاسو|Picasso', 'فان جوخ|Van Gogh', 'مايكل أنجلو|Michelangelo']),
    QuizQuestion('عامة|General', 'إيه أطول نهر في العالم (حسب أغلب المصادر)؟|What is the longest river in the world (by most sources)?', ['النيل|The Nile', 'الأمازون|The Amazon', 'المسيسيبي|The Mississippi', 'الدانوب|The Danube']),
    QuizQuestion('عامة|General', 'كام عضمة في جسم الإنسان البالغ؟|How many bones are in the adult human body?', ['206|206', '300|300', '150|150', '256|256']),
    QuizQuestion('عامة|General', 'النحل بيعمل إيه؟|What do bees make?', ['عسل|Honey', 'لبن|Milk', 'حرير|Silk', 'شمع بس|Only wax']),
    QuizQuestion('عامة|General', 'إيه عاصمة اليابان؟|What is the capital of Japan?', ['طوكيو|Tokyo', 'أوساكا|Osaka', 'كيوتو|Kyoto', 'سيول|Seoul']),
    QuizQuestion('عامة|General', 'كام لاعب في فريق كورة القدم جوه الملعب؟|How many players does a football team have on the pitch?', ['11|11', '10|10', '9|9', '12|12']),
    QuizQuestion('عامة|General', 'إيه الحيوان اللي بيتسمى سفينة الصحرا؟|Which animal is called the ship of the desert?', ['الجمل|Camel', 'الحصان|Horse', 'الفيل|Elephant', 'الحمار|Donkey']),
    QuizQuestion('عامة|General', 'كام قارة في العالم؟|How many continents are there?', ['7|7', '5|5', '6|6', '8|8']),
    QuizQuestion('عامة|General', 'إيه أكبر حيوان في العالم؟|What is the largest animal in the world?', ['الحوت الأزرق|Blue whale', 'الفيل|Elephant', 'الزرافة|Giraffe', 'القرش الأبيض|Great white shark']),
    QuizQuestion('عامة|General', 'الأسبوع فيه كام ساعة؟|How many hours are in a week?', ['168|168', '144|144', '120|120', '186|186']),
    QuizQuestion('عامة|General', 'إيه لون الزمرد؟|What colour is an emerald?', ['أخضر|Green', 'أحمر|Red', 'أزرق|Blue', 'أصفر|Yellow']),

    // ---------------- جغرافيا ----------------
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة فرنسا؟|What is the capital of France?', ['باريس|Paris', 'ليون|Lyon', 'مارسيليا|Marseille', 'نيس|Nice']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة السعودية؟|What is the capital of Saudi Arabia?', ['الرياض|Riyadh', 'جدة|Jeddah', 'مكة|Mecca', 'الدمام|Dammam']),
    QuizQuestion('جغرافيا|Geography', 'إيه أكبر دولة في العالم مساحة؟|What is the largest country by area?', ['روسيا|Russia', 'كندا|Canada', 'الصين|China', 'أمريكا|USA']),
    QuizQuestion('جغرافيا|Geography', 'إيه أعلى جبل في العالم؟|What is the highest mountain in the world?', ['إيفرست|Everest', 'كليمنجارو|Kilimanjaro', 'الألب|Mont Blanc', 'K2|K2']),
    QuizQuestion('جغرافيا|Geography', 'إيه أكبر صحرا حارة في العالم؟|What is the largest hot desert?', ['الصحرا الكبرى|The Sahara', 'صحرا جوبي|The Gobi', 'كالاهاري|The Kalahari', 'الربع الخالي|The Empty Quarter']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة المغرب؟|What is the capital of Morocco?', ['الرباط|Rabat', 'الدار البيضا|Casablanca', 'مراكش|Marrakesh', 'فاس|Fez']),
    QuizQuestion('جغرافيا|Geography', 'برج إيفل في أنهي مدينة؟|Which city is the Eiffel Tower in?', ['باريس|Paris', 'لندن|London', 'روما|Rome', 'برلين|Berlin']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة الإمارات؟|What is the capital of the UAE?', ['أبوظبي|Abu Dhabi', 'دبي|Dubai', 'الشارقة|Sharjah', 'العين|Al Ain']),
    QuizQuestion('جغرافيا|Geography', 'إيه أكبر قارة؟|What is the largest continent?', ['آسيا|Asia', 'أفريقيا|Africa', 'أوروبا|Europe', 'أمريكا الشمالية|North America']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة إيطاليا؟|What is the capital of Italy?', ['روما|Rome', 'ميلانو|Milan', 'فينيسيا|Venice', 'نابولي|Naples']),
    QuizQuestion('جغرافيا|Geography', 'البحر الأحمر بيفصل أفريقيا عن أنهي قارة؟|The Red Sea separates Africa from which continent?', ['آسيا|Asia', 'أوروبا|Europe', 'أستراليا|Australia', 'أمريكا|America']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة الأردن؟|What is the capital of Jordan?', ['عمّان|Amman', 'إربد|Irbid', 'العقبة|Aqaba', 'الزرقا|Zarqa']),
    QuizQuestion('جغرافيا|Geography', 'إيه أكتر دولة سكانها عرب؟|Which Arab country has the largest population?', ['مصر|Egypt', 'السعودية|Saudi Arabia', 'الجزائر|Algeria', 'العراق|Iraq']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة كندا؟|What is the capital of Canada?', ['أوتاوا|Ottawa', 'تورونتو|Toronto', 'فانكوفر|Vancouver', 'مونتريال|Montreal']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة تونس؟|What is the capital of Tunisia?', ['تونس|Tunis', 'صفاقس|Sfax', 'سوسة|Sousse', 'القيروان|Kairouan']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة أستراليا؟|What is the capital of Australia?', ['كانبرا|Canberra', 'سيدني|Sydney', 'ملبورن|Melbourne', 'بيرث|Perth']),
    QuizQuestion('جغرافيا|Geography', 'نهر النيل بيصب في أنهي بحر؟|Which sea does the Nile flow into?', ['المتوسط|The Mediterranean', 'الأحمر|The Red Sea', 'الأسود|The Black Sea', 'العربي|The Arabian Sea']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة لبنان؟|What is the capital of Lebanon?', ['بيروت|Beirut', 'طرابلس|Tripoli', 'صيدا|Sidon', 'صور|Tyre']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة السودان؟|What is the capital of Sudan?', ['الخرطوم|Khartoum', 'أم درمان|Omdurman', 'بورتسودان|Port Sudan', 'كسلا|Kassala']),
    QuizQuestion('جغرافيا|Geography', 'إيه عاصمة إسبانيا؟|What is the capital of Spain?', ['مدريد|Madrid', 'برشلونة|Barcelona', 'إشبيلية|Seville', 'فالنسيا|Valencia']),

    // ---------------- علوم ----------------
    QuizQuestion('علوم|Science', 'الميه بتغلي عند كام درجة مئوية (عند سطح البحر)؟|At what °C does water boil at sea level?', ['100|100', '90|90', '80|80', '120|120']),
    QuizQuestion('علوم|Science', 'إيه رمز الدهب في الجدول الدوري؟|What is the chemical symbol for gold?', ['Au|Au', 'Ag|Ag', 'Gd|Gd', 'Go|Go']),
    QuizQuestion('علوم|Science', 'النبات بياخد إيه من الهوا عشان يعمل البناء الضوئي؟|Which gas do plants take in for photosynthesis?', ['ثاني أكسيد الكربون|Carbon dioxide', 'الأكسجين|Oxygen', 'النيتروجين|Nitrogen', 'الهيليوم|Helium']),
    QuizQuestion('علوم|Science', 'إيه أقرب كوكب للشمس؟|Which planet is closest to the Sun?', ['عطارد|Mercury', 'الزهرة|Venus', 'المريخ|Mars', 'الأرض|Earth']),
    QuizQuestion('علوم|Science', 'القلب عنده كام أوضة؟|How many chambers does the human heart have?', ['4|4', '2|2', '3|3', '6|6']),
    QuizQuestion('علوم|Science', 'إيه الكوكب الأحمر؟|Which is the Red Planet?', ['المريخ|Mars', 'المشتري|Jupiter', 'الزهرة|Venus', 'زحل|Saturn']),
    QuizQuestion('علوم|Science', 'الميه بتتكون من هيدروجين و...؟|Water is made of hydrogen and…?', ['أكسجين|Oxygen', 'كربون|Carbon', 'نيتروجين|Nitrogen', 'كبريت|Sulphur']),
    QuizQuestion('علوم|Science', 'إيه أصلب مادة طبيعية؟|What is the hardest natural material?', ['الألماظ|Diamond', 'الحديد|Iron', 'الدهب|Gold', 'الزجاج|Glass']),
    QuizQuestion('علوم|Science', 'الضوء من الشمس بيوصل للأرض في حوالي قد إيه؟|About how long does sunlight take to reach Earth?', ['8 دقايق|8 minutes', 'ثانية|1 second', 'ساعة|1 hour', 'يوم|1 day']),
    QuizQuestion('علوم|Science', 'إيه العضو اللي بينضّف الدم في الجسم؟|Which organ filters the blood?', ['الكلى|Kidneys', 'الرئة|Lungs', 'المعدة|Stomach', 'القلب|Heart']),
    QuizQuestion('علوم|Science', 'إيه وحدة قياس الكهربا (فرق الجهد)؟|What is the unit of voltage?', ['الفولت|Volt', 'الوات|Watt', 'الأمبير|Ampere', 'الأوم|Ohm']),
    QuizQuestion('علوم|Science', 'إيه أكتر غاز في الهوا اللي بنتنفسه؟|Which gas makes up most of the air?', ['النيتروجين|Nitrogen', 'الأكسجين|Oxygen', 'ثاني أكسيد الكربون|Carbon dioxide', 'الأرجون|Argon']),
    QuizQuestion('علوم|Science', 'مين اكتشف الجاذبية لما التفاحة وقعت (حسب الحكاية)؟|Who, in the famous story, thought of gravity after an apple fell?', ['نيوتن|Newton', 'أينشتاين|Einstein', 'جاليليو|Galileo', 'إديسون|Edison']),
    QuizQuestion('علوم|Science', 'الحوت بيتنفس إزاي؟|How does a whale breathe?', ['برئة|With lungs', 'بخياشيم|With gills', 'من جلده|Through its skin', 'مبيتنفسش|It doesn’t']),
    QuizQuestion('علوم|Science', 'إيه أكبر عضو في جسم الإنسان؟|What is the largest organ of the human body?', ['الجلد|Skin', 'الكبد|Liver', 'المخ|Brain', 'الرئة|Lungs']),
    QuizQuestion('علوم|Science', 'إيه رقم الأس الهيدروجيني (pH) للميه النقية؟|What is the pH of pure water?', ['7|7', '0|0', '14|14', '5|5']),
    QuizQuestion('علوم|Science', 'القمر بيلف حوالين الأرض في حوالي؟|How long does the Moon take to orbit Earth (about)?', ['شهر|A month', 'يوم|A day', 'سنة|A year', 'أسبوع|A week']),
    QuizQuestion('علوم|Science', 'إيه المعدن السايل في درجة حرارة الأوضة؟|Which metal is liquid at room temperature?', ['الزئبق|Mercury', 'الحديد|Iron', 'النحاس|Copper', 'الألومنيوم|Aluminium']),
    QuizQuestion('علوم|Science', 'الصوت بيمشي أسرع في؟|Sound travels fastest through…?', ['الحديد|Steel', 'الهوا|Air', 'الميه|Water', 'الفراغ|A vacuum']),
    QuizQuestion('علوم|Science', 'إيه اللي بيدّي النبات لونه الأخضر؟|What gives plants their green colour?', ['الكلوروفيل|Chlorophyll', 'الميلانين|Melanin', 'النشا|Starch', 'السكر|Sugar']),

    // ---------------- رياضة ----------------
    QuizQuestion('رياضة|Sports', 'كأس العالم لكورة القدم بيتلعب كل كام سنة؟|How often is the football World Cup held?', ['4 سنين|Every 4 years', 'سنتين|Every 2 years', 'كل سنة|Every year', '5 سنين|Every 5 years']),
    QuizQuestion('رياضة|Sports', 'ماتش كورة القدم الرسمي كام دقيقة (من غير وقت ضايع)؟|How long is a football match (without stoppage time)?', ['90|90', '80|80', '100|100', '60|60']),
    QuizQuestion('رياضة|Sports', 'كام لاعب في فريق كورة السلة جوه الملعب؟|How many players per basketball team are on court?', ['5|5', '6|6', '7|7', '4|4']),
    QuizQuestion('رياضة|Sports', 'الأولمبياد الصيفي بيتعمل كل كام سنة؟|How often are the Summer Olympics held?', ['4 سنين|Every 4 years', 'سنتين|Every 2 years', '3 سنين|Every 3 years', '6 سنين|Every 6 years']),
    QuizQuestion('رياضة|Sports', 'في التنس، الماتش بيبدأ بنتيجة "لاف" يعني إيه؟|In tennis, what does "love" mean?', ['صفر|Zero', 'تعادل|A tie', 'كسب|A win', 'خطأ|A fault']),
    QuizQuestion('رياضة|Sports', 'كام حلقة في شعار الأولمبياد؟|How many rings are in the Olympic logo?', ['5|5', '4|4', '6|6', '7|7']),
    QuizQuestion('رياضة|Sports', 'الشطرنج فيه كام قطعة لكل لاعب في الأول؟|How many pieces does each chess player start with?', ['16|16', '12|12', '18|18', '20|20']),
    QuizQuestion('رياضة|Sports', 'سباق الماراتون طوله حوالي كام كيلو؟|About how long is a marathon?', ['42 كم|42 km', '21 كم|21 km', '10 كم|10 km', '50 كم|50 km']),
    QuizQuestion('رياضة|Sports', 'في كورة القدم، الكارت اللي بيطرد اللاعب لونه إيه؟|In football, what colour card sends a player off?', ['أحمر|Red', 'أصفر|Yellow', 'أخضر|Green', 'أزرق|Blue']),
    QuizQuestion('رياضة|Sports', 'لعبة كورة الطايرة الفريق فيها كام لاعب جوه الملعب؟|How many players per volleyball team are on court?', ['6|6', '5|5', '7|7', '9|9']),
    QuizQuestion('رياضة|Sports', 'الكاراتيه أصلها منين؟|Where does karate come from?', ['اليابان|Japan', 'الصين|China', 'كوريا|Korea', 'تايلاند|Thailand']),
    QuizQuestion('رياضة|Sports', 'إيه الرياضة اللي فيها "هوم رن"؟|Which sport has a "home run"?', ['البيسبول|Baseball', 'الكريكيت|Cricket', 'الرجبي|Rugby', 'الجولف|Golf']),
    QuizQuestion('رياضة|Sports', 'ملعب التنس الأشهر في ويمبلدون أرضيته إيه؟|What is the Wimbledon court surface?', ['نجيلة|Grass', 'طين|Clay', 'أسفلت|Hard court', 'خشب|Wood']),
    QuizQuestion('رياضة|Sports', 'كام نقطة الرمية من بعيد (ورا القوس) في كورة السلة؟|How many points is a shot from beyond the arc in basketball?', ['3|3', '2|2', '4|4', '1|1']),
    QuizQuestion('رياضة|Sports', 'في الملاكمة، الجولة الرسمية للمحترفين كام دقيقة؟|How long is a professional boxing round?', ['3 دقايق|3 minutes', 'دقيقتين|2 minutes', '5 دقايق|5 minutes', 'دقيقة|1 minute']),
    QuizQuestion('رياضة|Sports', 'الجولف الهدف فيه إنك...؟|In golf, the aim is to…?', ['تخلّص بأقل ضربات|Finish in the fewest strokes', 'تخلّص بأكتر ضربات|Use the most strokes', 'تجري أسرع|Run the fastest', 'تجيب جول|Score goals']),
    QuizQuestion('رياضة|Sports', 'لعبة البينج بونج اسمها الرسمي؟|What is the official name of ping-pong?', ['تنس الطاولة|Table tennis', 'تنس الأرض|Lawn tennis', 'الإسكواش|Squash', 'البادل|Padel']),
    QuizQuestion('رياضة|Sports', 'في السباحة، أسرع طريقة عادةً؟|Which swimming stroke is usually the fastest?', ['الحرة|Freestyle', 'الصدر|Breaststroke', 'الظهر|Backstroke', 'الفراشة|Butterfly']),
    QuizQuestion('رياضة|Sports', 'كام شوط في ماتش كورة اليد؟|How many halves are in a handball match?', ['2|2', '3|3', '4|4', '1|1']),
    QuizQuestion('رياضة|Sports', 'الضربة اللي من علامة الجزا في كورة القدم بتتسمى؟|A kick from the penalty spot is called a…?', ['ضربة جزا|Penalty', 'ركنية|Corner', 'تسلل|Offside', 'رمية تماس|Throw-in']),

    // ---------------- مصر ----------------
    QuizQuestion('مصر|Egypt', 'إيه عاصمة مصر؟|What is the capital of Egypt?', ['القاهرة|Cairo', 'الإسكندرية|Alexandria', 'الجيزة|Giza', 'أسوان|Aswan']),
    QuizQuestion('مصر|Egypt', 'الهرم الأكبر اتبنى لمين؟|Who was the Great Pyramid built for?', ['خوفو|Khufu', 'خفرع|Khafre', 'منقرع|Menkaure', 'رمسيس التاني|Ramesses II']),
    QuizQuestion('مصر|Egypt', 'السد العالي في أنهي مدينة؟|Which city is the High Dam in?', ['أسوان|Aswan', 'الأقصر|Luxor', 'قنا|Qena', 'المنيا|Minya']),
    QuizQuestion('مصر|Egypt', 'قناة السويس بتربط البحر المتوسط بأنهي بحر؟|The Suez Canal links the Mediterranean with which sea?', ['الأحمر|The Red Sea', 'الأسود|The Black Sea', 'العربي|The Arabian Sea', 'الميت|The Dead Sea']),
    QuizQuestion('مصر|Egypt', 'مين اسكندر اللي اتسمّت الإسكندرية على اسمه؟|Who is Alexandria named after?', ['الإسكندر الأكبر|Alexander the Great', 'كليوباترا|Cleopatra', 'يوليوس قيصر|Julius Caesar', 'محمد علي|Muhammad Ali Pasha']),
    QuizQuestion('مصر|Egypt', 'حجر رشيد ساعد العلما يفهموا إيه؟|What did the Rosetta Stone help scholars read?', ['الهيروغليفي|Hieroglyphs', 'اللاتيني|Latin', 'العبري|Hebrew', 'الصيني|Chinese']),
    QuizQuestion('مصر|Egypt', 'مين كاتب "الثلاثية" (بين القصرين)؟|Who wrote the Cairo Trilogy?', ['نجيب محفوظ|Naguib Mahfouz', 'طه حسين|Taha Hussein', 'توفيق الحكيم|Tawfiq al-Hakim', 'يوسف إدريس|Yusuf Idris']),
    QuizQuestion('مصر|Egypt', 'معبد الكرنك في أنهي مدينة؟|Which city is Karnak Temple in?', ['الأقصر|Luxor', 'أسوان|Aswan', 'القاهرة|Cairo', 'سوهاج|Sohag']),
    QuizQuestion('مصر|Egypt', 'أبو الهول راسه راس إيه وجسمه جسم إيه؟|The Sphinx has a human head and the body of a…?', ['أسد|Lion', 'حصان|Horse', 'نسر|Eagle', 'تمساح|Crocodile']),
    QuizQuestion('مصر|Egypt', 'أم كلثوم اتلقّبت بإيه؟|What was Umm Kulthum called?', ['كوكب الشرق|Star of the East', 'العندليب|The Nightingale', 'سيدة الشاشة|Lady of the Screen', 'الست الأولى|First Lady']),
    QuizQuestion('مصر|Egypt', 'العندليب الأسمر لقب مين؟|Who was called the Dark-Skinned Nightingale?', ['عبد الحليم حافظ|Abdel Halim Hafez', 'محمد عبد الوهاب|Mohamed Abdel Wahab', 'فريد الأطرش|Farid al-Atrash', 'محمد منير|Mohamed Mounir']),
    QuizQuestion('مصر|Egypt', 'إيه أكبر بحيرة صناعية في مصر؟|What is Egypt’s largest artificial lake?', ['بحيرة ناصر|Lake Nasser', 'بحيرة قارون|Lake Qarun', 'البحيرات المرة|The Bitter Lakes', 'بحيرة المنزلة|Lake Manzala']),
    QuizQuestion('مصر|Egypt', 'مين الملكة اللي اتبنالها معبد الدير البحري؟|Which queen built the temple at Deir el-Bahari?', ['حتشبسوت|Hatshepsut', 'نفرتيتي|Nefertiti', 'كليوباترا|Cleopatra', 'نفرتاري|Nefertari']),
    QuizQuestion('مصر|Egypt', 'مقبرة توت عنخ آمون اتكتشفت سنة كام؟|In which year was Tutankhamun’s tomb found?', ['1922|1922', '1882|1882', '1952|1952', '1902|1902']),
    QuizQuestion('مصر|Egypt', 'جبل موسى في أنهي محافظة؟|Which governorate is Mount Sinai in?', ['جنوب سينا|South Sinai', 'شمال سينا|North Sinai', 'البحر الأحمر|Red Sea', 'السويس|Suez']),
    QuizQuestion('مصر|Egypt', 'نهر النيل في مصر بيجري من...؟|In Egypt, the Nile flows from…?', ['الجنوب للشمال|South to north', 'الشمال للجنوب|North to south', 'الشرق للغرب|East to west', 'الغرب للشرق|West to east']),
    QuizQuestion('مصر|Egypt', 'إيه اسم العملة المصرية؟|What is Egypt’s currency?', ['الجنيه|The pound', 'الدينار|The dinar', 'الريال|The riyal', 'الدرهم|The dirham']),
    QuizQuestion('مصر|Egypt', 'واحة سيوة في أنهي صحرا؟|Which desert is Siwa Oasis in?', ['الغربية|The Western Desert', 'الشرقية|The Eastern Desert', 'سينا|Sinai', 'النوبة|Nubia']),
    QuizQuestion('مصر|Egypt', 'مين أول مصري ياخد نوبل في الكيميا؟|Who was the first Egyptian to win the Nobel Prize in Chemistry?', ['أحمد زويل|Ahmed Zewail', 'مجدي يعقوب|Magdi Yacoub', 'فاروق الباز|Farouk El-Baz', 'مصطفى مشرفة|Mustafa Musharafa']),
    QuizQuestion('مصر|Egypt', 'منارة الإسكندرية القديمة كانت من عجايب الدنيا؟|Was the ancient Lighthouse of Alexandria one of the Seven Wonders?', ['أيوه|Yes', 'لأ|No', 'كانت في روما|It was in Rome', 'لسه موجودة|It still stands']),
  ];
}
