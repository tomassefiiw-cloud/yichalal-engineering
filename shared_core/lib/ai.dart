import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'config.dart';

/// AI Diagnosis via OpenRouter.
///
/// Cascades through: primary model → backup model → local rule engine.
/// Always returns SOMETHING useful, never blocks on a hung network call.
class AiDiagnosis {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 12),
  ));

  /// Streams a single chunk (the full response) — kept as Stream for
  /// future-proofing if we add real SSE streaming later.
  static Stream<String> diagnoseStream(String symptom) async* {
    if (AppConfig.openRouterKey.isEmpty) {
      yield _localDiagnose(symptom);
      return;
    }

    // Try primary model
    final primary = await _tryModel(symptom, AppConfig.openRouterModel);
    if (primary != null) {
      yield primary;
      return;
    }

    // Try backup model
    final backup = await _tryModel(symptom, AppConfig.openRouterBackupModel);
    if (backup != null) {
      yield backup;
      return;
    }

    // Both AI models failed — use local engine but DON'T say "offline" if
    // the network was reachable (we tried 2 models and got real errors back).
    yield _localDiagnose(symptom);
  }

  static Future<String?> _tryModel(String symptom, String model) async {
    try {
      final res = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.openRouterKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://yichalal.app',
            'X-Title': 'Yichalal Engineering',
          },
          responseType: ResponseType.json,
        ),
        data: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a senior automotive mechanic in Ethiopia advising a car owner.
The user will describe a car symptom. Reply concisely in 4 labeled sections (plain text, no markdown):

Probable cause: <one short sentence>
Severity: low | medium | high | critical
Estimated repair: <one short sentence>
Estimated cost in ETB: <min> - <max>

Then 1-2 short "Next step:" bullets. Total under 120 words. Be specific and practical.''',
            },
            {'role': 'user', 'content': symptom},
          ],
          'max_tokens': 350,
          'temperature': 0.3,
        }),
      );
      final choices = res.data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final content = choices[0]['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) return null;
      return content.trim();
    } catch (_) {
      return null;
    }
  }

  static String _localDiagnose(String input) {
    final q = input.toLowerCase();
    final hits = <_Rule>[];
    for (final r in _rules) {
      for (final k in r.keywords) {
        if (q.contains(k)) {
          hits.add(r);
          break;
        }
      }
    }
    if (hits.isEmpty) {
      return '''Probable cause: Symptom not yet recognised — please describe more details (when does it happen? what does it sound like?).
Severity: unknown
Estimated repair: Workshop diagnostic recommended
Estimated cost in ETB: 300 - 1500
Next step: Book a workshop diagnostic
Next step: Note any warning lights or unusual sounds''';
    }
    const sevRank = {
      'critical': 4,
      'high': 3,
      'medium': 2,
      'low': 1,
      'unknown': 0,
    };
    hits.sort((a, b) =>
        (sevRank[b.severity] ?? 0).compareTo(sevRank[a.severity] ?? 0));
    final r = hits.first;
    return '''Probable cause: ${r.cause}
Severity: ${r.severity}
Estimated repair: ${r.repair}
Estimated cost in ETB: ${r.min.toInt()} - ${r.max.toInt()}
Next step: ${r.steps.first}${r.steps.length > 1 ? '\nNext step: ${r.steps[1]}' : ''}''';
  }

  static const quickSymptoms = [
    'Check engine light',
    'Overheating',
    "Won't start",
    'Brake squeal',
    'Oil leak',
    'AC not cold',
    'Strange noise',
    'White smoke',
    'Vibration',
    'Battery dead',
  ];

  static final _rules = [
    _Rule(['overheat', 'hot', 'steam', 'ሙቀት'], 'Cooling system issue — possibly low coolant, faulty thermostat, water-pump leak, or radiator clog', 'high', 'Coolant flush / thermostat / water pump or radiator repair', 1500, 9000, ['Stop driving — let engine cool', 'Check coolant level when cold, then book workshop']),
    _Rule(['check engine', 'engine light', 'መብራት'], 'On-board diagnostics has stored a fault code — could be loose fuel cap, misfire, or O2 sensor', 'medium', 'OBD-II scan + targeted repair', 400, 6000, ['Tighten fuel cap and drive 20 km', 'If light stays, visit verified mechanic for OBD scan']),
    _Rule(["won't start", 'no start', 'wont start', 'ስታርት'], 'Starting issue — battery, starter motor, fuel delivery, or ignition', 'high', 'Battery + starter test, fuel pressure check', 800, 9500, ['Try jump-start; if it starts, suspect battery', 'If only clicking sound, suspect starter solenoid']),
    _Rule(['battery', 'ባትሪ'], 'Battery weak or dead — internal resistance high or charging system fault', 'medium', 'Battery load test + replacement', 2500, 8000, ['Jump-start to drive home', 'Replace if battery is older than 3 years']),
    _Rule(['brake', 'squeal', 'grind', 'ብሬክ'], 'Brake pad / rotor wear or hydraulic issue', 'high', 'Pad replacement, rotor resurface, fluid bleed', 2000, 12000, ['Avoid hard braking', 'Book brake inspection within 24 hours']),
    _Rule(['oil leak', 'leak', 'ዘይት'], 'Engine or transmission oil leak — gasket, seal, drain plug, or oil pan', 'medium', 'Reseal or gasket replacement', 1200, 8500, ['Check oil level daily until fixed', 'Place cardboard under car to identify leak location']),
    _Rule(['vibrate', 'shake', 'ይንቀጠቀጣል'], 'Wheel imbalance, alignment issue, or worn CV joint', 'medium', 'Alignment + balancing, possibly CV joint replacement', 900, 6500, ['Avoid high-speed driving until fixed', 'Visit alignment shop']),
    _Rule(['ac', 'air conditioning', 'ኤሲ'], 'AC system: low refrigerant, compressor, or condenser issue', 'low', 'Refrigerant top-up + leak check', 1500, 12000, ['Avoid running AC at max in heat', 'Book AC workshop service']),
    _Rule(['noise', 'knock', 'tick', 'ድምጽ'], 'Abnormal noise — could be valvetrain, bearings, or accessory belt', 'medium', 'Diagnostic listening + targeted repair', 500, 18000, ['Note exactly when noise occurs', 'Workshop diagnostic recommended']),
    _Rule(['smoke', 'white smoke', 'ጭስ'], 'Exhaust smoke — white = coolant in combustion, blue = oil burning, black = rich fuel mix', 'high', 'Head gasket, valve seals, or fuel system repair', 4000, 35000, ['Stop driving if heavy white smoke', 'Tow to workshop immediately']),
    _Rule(['transmission', 'gear', 'shift', 'slipping', 'ጊር'], 'Transmission slip or shift problem — fluid level, solenoid, or clutch wear', 'high', 'Fluid service, solenoid replacement, or rebuild', 2500, 50000, ['Avoid towing loads', 'Book transmission specialist']),
    _Rule(['alternator', 'charging', 'አልተርኔተር'], 'Charging system fault — alternator, regulator, or belt', 'high', 'Alternator test/replacement, belt service', 4000, 14000, ['Drive directly to workshop — battery will drain']),
    _Rule(['suspension', 'shock', 'strut'], 'Suspension wear — shocks, struts, bushings, or ball joints', 'medium', 'Component replacement', 1500, 14000, ['Avoid potholes', 'Book inspection']),
    _Rule(['fuel', 'mileage', 'ነዳጅ'], 'Poor fuel economy — O2 sensor, MAF, injectors, tire pressure, or driving habits', 'low', 'Diagnostics + tune-up', 500, 8000, ['Check tire pressure first', 'Replace dirty air filter']),
    _Rule(['stall', 'dies', 'ይጠፋል'], 'Engine stalling — fuel pump, idle air control, sensors, or ignition', 'high', 'Diagnostic + targeted repair', 1200, 12000, ['Avoid highway driving until fixed']),
  ];
}

class _Rule {
  final List<String> keywords;
  final String cause, severity, repair;
  final double min, max;
  final List<String> steps;
  _Rule(this.keywords, this.cause, this.severity, this.repair, this.min, this.max, this.steps);
}
