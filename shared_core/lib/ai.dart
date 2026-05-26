import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'config.dart';

/// AI Diagnosis via OpenRouter (DeepSeek). Falls back to local rule engine if
/// the API call fails or the device is offline.
class AiDiagnosis {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Streams partial chunks as DeepSeek responds. Falls back to local rules.
  static Stream<String> diagnoseStream(String symptom) async* {
    if (AppConfig.openRouterKey.isEmpty) {
      yield _localDiagnose(symptom);
      return;
    }
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
          'model': AppConfig.openRouterModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a senior automotive mechanic in Ethiopia. The user will describe a car symptom.
Reply concisely in 4 short labeled sections, plain text, no markdown:
Probable cause: ...
Severity: low | medium | high | critical
Estimated repair: ...
Estimated cost in ETB: <min> - <max>
Then 1-2 short "Next step:" bullets.''',
            },
            {'role': 'user', 'content': symptom},
          ],
          'max_tokens': 400,
        }),
      );
      final content = res.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        yield _localDiagnose(symptom);
      } else {
        yield content.trim();
      }
    } on DioException catch (e) {
      // Network / API failure → fall back to local engine.
      yield _localDiagnose(symptom) + '\n\n_(Offline diagnosis — cloud AI unreachable: ${e.type.name})_';
    } catch (_) {
      yield _localDiagnose(symptom);
    }
  }

  static String _localDiagnose(String input) {
    final q = input.toLowerCase();
    final hits = <_Rule>[];
    for (final r in _rules) {
      for (final k in r.keywords) {
        if (q.contains(k)) { hits.add(r); break; }
      }
    }
    if (hits.isEmpty) {
      return '''Probable cause: Symptom not yet recognised — please describe more details.
Severity: unknown
Estimated repair: Workshop diagnostic recommended
Estimated cost in ETB: 300 - 1500
Next step: Book a workshop diagnostic''';
    }
    const sevRank = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1, 'unknown': 0};
    hits.sort((a, b) => (sevRank[b.severity] ?? 0).compareTo(sevRank[a.severity] ?? 0));
    final r = hits.first;
    return '''Probable cause: ${r.cause}
Severity: ${r.severity}
Estimated repair: ${r.repair}
Estimated cost in ETB: ${r.min.toInt()} - ${r.max.toInt()}
Next step: ${r.steps.first}''';
  }

  static const quickSymptoms = ['Check engine light', 'Overheating', 'Won\'t start', 'Brake squeal', 'Oil leak', 'AC not cold', 'Strange noise', 'White smoke', 'Vibration', 'Battery dead'];

  static final _rules = [
    _Rule(['overheat', 'hot', 'steam', 'ሙቀት'], 'Cooling system issue', 'high', 'Coolant flush / thermostat / water pump', 1500, 9000, ['Stop driving — let engine cool', 'Book workshop visit']),
    _Rule(['check engine', 'engine light', 'መብራት'], 'OBD fault stored', 'medium', 'OBD-II scan + targeted repair', 400, 6000, ['Tighten fuel cap', 'Visit verified mechanic']),
    _Rule(['won\'t start', 'no start', 'ስታርት'], 'Battery, starter, or fuel delivery', 'high', 'Battery/starter test', 800, 9500, ['Try jump-start', 'Book emergency roadside']),
    _Rule(['battery', 'ባትሪ'], 'Battery weak or dead', 'medium', 'Battery test/replacement', 2500, 8000, ['Jump-start', 'Replace if >3 years old']),
    _Rule(['brake', 'squeal', 'grind', 'ብሬክ'], 'Brake pad/rotor wear', 'high', 'Pad replacement, rotor resurface', 2000, 12000, ['Avoid hard braking', 'Inspect within 24h']),
    _Rule(['oil leak', 'leak', 'ዘይት'], 'Engine/transmission oil leak', 'medium', 'Reseal / gasket replacement', 1200, 8500, ['Check oil daily', 'Schedule workshop']),
    _Rule(['vibrate', 'shake', 'ይንቀጠቀጣል'], 'Wheel imbalance / alignment / CV joint', 'medium', 'Alignment + balancing', 900, 6500, ['Visit alignment shop']),
    _Rule(['ac', 'air conditioning', 'ኤሲ'], 'AC: low refrigerant or compressor', 'low', 'Refrigerant top-up + leak check', 1500, 12000, ['Book AC service']),
    _Rule(['noise', 'knock', 'ድምጽ'], 'Abnormal noise — valvetrain/bearings/exhaust', 'medium', 'Diagnostic listening', 500, 18000, ['Workshop visit']),
    _Rule(['smoke', 'ጭስ'], 'Exhaust smoke', 'high', 'Head gasket / valve seals / fuel system', 4000, 35000, ['Tow to workshop']),
    _Rule(['transmission', 'gear', 'ጊር'], 'Transmission slip / shift', 'high', 'Fluid service / solenoid / rebuild', 2500, 50000, ['Avoid towing loads']),
    _Rule(['alternator', 'charging', 'አልተርኔተር'], 'Charging system', 'high', 'Alternator test/replacement', 4000, 14000, ['Drive to workshop ASAP']),
    _Rule(['suspension', 'shock', 'strut'], 'Suspension wear', 'medium', 'Component replacement', 1500, 14000, ['Avoid potholes']),
    _Rule(['fuel', 'mileage', 'ነዳጅ'], 'Poor fuel economy', 'low', 'Diagnostics + tune-up', 500, 8000, ['Check tire pressure']),
    _Rule(['stall', 'dies', 'ይጠፋል'], 'Engine stalling', 'high', 'Diagnostic + targeted repair', 1200, 12000, ['Avoid highway driving']),
  ];
}

class _Rule {
  final List<String> keywords;
  final String cause, severity, repair;
  final double min, max;
  final List<String> steps;
  _Rule(this.keywords, this.cause, this.severity, this.repair, this.min, this.max, this.steps);
}
