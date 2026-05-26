import 'package:flutter/widgets.dart';

enum AppLang { en, am, om }

class S {
  final AppLang lang;
  S(this.lang);
  static S of(BuildContext context) {
    final inh = context.dependOnInheritedWidgetOfExactType<_LangScope>();
    return inh?.s ?? S(AppLang.en);
  }
  String t(String k) => _all[k]?[lang.index] ?? k;
  String get appName => 'Yichalal Engineering';

  static const Map<String, List<String>> _all = {
    'login': ['Login', 'ግባ', 'Seeni'],
    'logout': ['Log out', 'ውጣ', 'Bahi'],
    'signup': ['Sign Up', 'ተመዝገብ', 'Galmaa\'i'],
    'phone': ['Phone Number', 'የስልክ ቁጥር', 'Lakkoofsa'],
    'send_otp': ['Send code', 'ኮድ ላክ', 'Koodii ergi'],
    'verify': ['Verify', 'አረጋግጥ', 'Mirkaneessi'],
    'otp_code': ['Verification code', 'የማረጋገጫ ኮድ', 'Koodii'],
    'full_name': ['Full Name', 'ሙሉ ስም', 'Maqaa'],
    'email_optional': ['Email (optional)', 'ኢሜል', 'Imeelii'],
    'address': ['Address / Landmark', 'አድራሻ', 'Teessoo'],
    'create_account': ['Create account', 'መለያ ፍጠር', 'Akkaawuntii uumi'],
    'have_account': ['I have an account', 'መለያ አለኝ', 'Akkaawuntii qaba'],
    'home': ['Home', 'መነሻ', 'Mana'],
    'garage': ['Garage', 'ጋራዥ', 'Garaajii'],
    'diagnose': ['AI Diagnosis', 'AI ምርመራ', 'Qorannoo'],
    'bookings': ['Bookings', 'ቀጠሮዎች', 'Beellama'],
    'wallet': ['Wallet', 'ዋሌት', 'Walleetii'],
    'jobs': ['Jobs', 'ስራዎች', 'Hojii'],
    'requests': ['Requests', 'ጥያቄዎች', 'Gaaffii'],
    'route': ['Route', 'መንገድ', 'Karaa'],
    'earnings': ['Earnings', 'ገቢ', 'Galii'],
    'inventory': ['Inventory', 'ክምችት', 'Kuusaa'],
    'add_vehicle': ['Add Vehicle', 'ተሽከርካሪ ጨምር', 'Konkolaataa'],
    'pay_now': ['Pay Now', 'አሁን ክፈል', 'Amma kaffali'],
    'language': ['Language', 'ቋንቋ', 'Afaan'],
    'theme': ['Theme', 'ገጽታ', 'Bifa'],
    'profile': ['Profile', 'መገለጫ', 'Profaayilii'],
    'settings': ['Settings', 'ቅንብሮች', 'Qindaa\'inoota'],
    'describe_problem': ['Describe the problem', 'ችግሩን ግለፅ', 'Rakkoo ibsi'],
    'create_booking': ['Create Booking', 'ቀጠሮ ፍጠር', 'Beellama uumi'],
    'pick_date_time': ['Pick date & time', 'ቀን እና ሰዓት ምረጥ', 'Guyyaa fili'],
    'save_changes': ['Save changes', 'ለውጦች አስቀምጥ', 'Jijjiirama olkaa\'i'],
    'preferences': ['Preferences', 'ምርጫዎች', 'Filannoo'],
    'about': ['About', 'ስለ', 'Waa\'ee'],
    'notifications': ['Notifications', 'ማሳወቂያዎች', 'Beeksisa'],
    'recent_bookings': ['Recent bookings', 'የቅርብ ጊዜ ቀጠሮዎች', 'Beellama dhihoo'],
    'verified_mechanics': ['Verified mechanics', 'የተረጋገጡ ሜካኒኮች', 'Meekaanikii mirkanaa\'e'],
    'quick_service': ['Quick service', 'ፈጣን አገልግሎት', 'Tajaajila ariifataa'],
    'no_bookings': ['No bookings yet', 'እስካሁን ቀጠሮ የለም', 'Beellama hin jiru'],
  };
}

class _LangScope extends InheritedWidget {
  final S s;
  const _LangScope({required this.s, required super.child});
  @override
  bool updateShouldNotify(_LangScope old) => old.s.lang != s.lang;
}

class LangProvider extends StatefulWidget {
  final AppLang initial;
  final Widget Function(BuildContext, AppLang, void Function(AppLang)) builder;
  const LangProvider({super.key, required this.initial, required this.builder});
  @override
  State<LangProvider> createState() => _LangProviderState();
}

class _LangProviderState extends State<LangProvider> {
  late AppLang _lang = widget.initial;

  @override
  void didUpdateWidget(covariant LangProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _lang = widget.initial;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _LangScope(s: S(_lang), child: widget.builder(context, _lang, (l) => setState(() => _lang = l)));
}
