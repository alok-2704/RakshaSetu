import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String apiKey =
    String.fromEnvironment('GROQ_API_KEY');

  static const String _url =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model =
      'llama-3.1-8b-instant';

  static Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> _post(
    List<Map<String, String>> messages,
  ) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: _headers(),
      body: jsonEncode({
        "model": _model,
        "messages": messages,
        "temperature": 0.2,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data.toString());
    }

    return data;
  }

  static Future<Map<String, String>>
      analyzeIncident(String text) async {
    final data = await _post([
      {
        "role": "system",
        "content": '''
You are an AI emergency response assistant for Indian organizations such as colleges, offices, factories, hospitals, malls, and campuses.

The output is for ADMIN / RESPONSE TEAMS, not students.

Context:
- Use practical Indian workplace/campus emergency workflows.
- Internal response teams include Security, Fire Safety Staff, Medical Room, Facility Team, Admin Office, Warden, Supervisors.
- Prioritize internal rapid response first.
- Escalate to external emergency services only for severe situations.

Rules:
- Action must be short, practical, and responder-focused.
- Do NOT give student/public advice here.
- Use terms like dispatch guard, send medical staff, isolate area, begin evacuation, secure gate, call facility team.
- Avoid American emergency language .
- Be specific to the incident.
- Match response to incident scale.
- Do not include unnecessary teams.
- Do not overreact.
Return ONLY valid JSON:
{
  "severity":"High/Medium/Low",
  "priority":"Immediate/Urgent/Normal",
  "action":"short responder action"
}

No markdown.
No extra text.
'''
      },
      {
        "role": "user",
        "content": "Incident: $text",
      }
    ]);

    final raw = data["choices"][0]["message"]
            ["content"]
        .toString()
        .trim();

    final clean = raw
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();

    final parsed = jsonDecode(clean);

    return {
      "severity":
          parsed["severity"] ?? "Medium",
      "priority":
          parsed["priority"] ?? "Urgent",
      "action":
          parsed["action"] ?? "Check alert",
    };
  }

  static Future<String>
      generateStudentGuide(
    String text,
  ) async {
    final data = await _post([
      {
        "role": "system",
        "content": '''
You give emergency safety guidance to users in India during incidents in campuses, offices, factories, and public institutions.

You provide post-alert safety guidance to users after an emergency has already been reported through the app.

Important:
- Assume the correct response team has already been notified.
- Do NOT tell users to call security, staff, responders, or authorities again unless explicitly necessary.
- Focus only on what the user should do now.

Context:
Incidents may involve fire, medical, fights, suspicious activity, theft, smoke, crowd issues, etc.

Rules:
- Maximum 4 short lines
- Calm and practical
- Specific to the incident
- No overreaction
- No unnecessary evacuation advice
- Plain text only

'''
      },
      {
        "role": "user",
        "content": "Incident: $text",
      }
    ]);

    return data["choices"][0]["message"]
            ["content"]
        .toString()
        .trim();
  }
}