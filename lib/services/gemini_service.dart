import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyDc8ykcus5qDGFyZfKaPWcRJ52wuEVGWs0";

  // FINE-TUNED GEMINI PROMPT
  final String geminiPrompt = """
You are a friendly health expert chatbot. Provide short, crisp, and precise answers or suggestions. Always include exact numerical values for calories and macronutrients; never give ranges or estimates.

1. When the user only provides food names (no questions):
   - Start the reply with: Food Item: <food_name>
   - Then provide total nutritional values (for all food items combined) in this exact format:
     Calories: X
     Carbs: Xg
     Protein: Xg
     Fat: Xg
   - Below that, list each individual food with its macros:
     <food_name> :Calories: Xkcal, Carbs: Xg, Protein: Xg, Fat: Xg.
   - End with a brief tip or remark about the food(s).

2. When the user asks a question about a food:
   - Respond casually in a sentence.
   - Include numerical values only if relevant.
   - End with a tip or recommendation.

3. When the user only provides exercise names (no questions):
   - Start with: Exercise: <exercise_name>
   - Then provide only total calories burned in this exact format:
     Calories: Xkcal
   - Below that, list each individual exercise with its calorie:
    <exercise_name> :Calories: Xkcal.
   - End with a short fitness tip or remark.

4. When the user asks a question about an exercise:
   - Respond casually in a sentence.
   - Include calories only if relevant.
   - End with a fitness tip.

Strict instructions:
- Do not deviate from the formats above.
- Do not mix food and exercise responses.
- Always provide a remark/tip at the end.
- Use exact numbers for calories, carbs, protein, and fat.
- Ensure outputs are easily parsable programmatically.
""";



  // TEXT MESSAGE
  Future<String> sendText(String text) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {"text": text}
          ]
        }
      ],
      "system_instruction": {
        "parts": [
          {"text": geminiPrompt}
        ]
      }
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    return data["candidates"][0]["content"]["parts"][0]["text"];
  }

  // IMAGE MESSAGE
  Future<String> sendImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Encode(bytes)
              }
            },
            {"text": "Analyze this image related to health and nutrition."}
          ]
        }
      ],
      "system_instruction": {
        "parts": [
          {"text": geminiPrompt}
        ]
      }
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    return data["candidates"][0]["content"]["parts"][0]["text"];
  }

  // ✅ NEW: AI PLANNER GENERATION


// ✅ UPDATED: AI PLANNER GENERATION
  Future<Map<String, dynamic>> generateFitnessPlan(Map<String, dynamic> userData) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final double currentWeight = (userData['weight'] as num?)?.toDouble() ?? 70.0;
    final double targetWeight = (userData['target_weight'] as num?)?.toDouble() ?? currentWeight;
    final String targetBodyFat = userData['fat'] ;

    final prompt = """
ACT AS A PROFESSIONAL FITNESS COACH. 
The following targets are FIXED by the user. Do not change them:
- TARGET WEIGHT: $targetWeight Kg
- TARGET BODY FAT: $targetBodyFat 
Calculate the plan based on moving from ${currentWeight}kg to ${targetWeight}kg.

USER DATA:
- Gender: ${userData['gender']}, Age: ${userData['age']}, Height: ${userData['height']}cm.
- Goal: ${userData['goal']}, Focus: ${userData['focus_areas']}, Location: ${userData['location']}, Activity Level: ${userData['activity_level']}.
- Injuries: ${userData['injuries']}.

STRICT JSON REQUIREMENTS:
1. NO ZERO VALUES for targets.
2. target_calories: 1500-3500.
3. target_steps: 5000-15000.
4. Activity minutes (Gym/Yoga/Sports): Provide positive values for all and MAX value should be 120 min.IMPORTANT: DONT give beyond 120 min for YOGA,GYM AND SPORTS.
5. estimated_weeks: Calculate realistic duration to reach the target weight of $targetWeight kg.
6. Formulate the exercises, diet,supplements,motivation tips and lifestyle plans considering the GOAL and ACTIVITY LEVEL. 
7. Also mention the user given input in your responses by justifying why you have given the plan.
8. Mention clear headings and highlight important indicators. be specific with plan. it should be super personalised based on every metric and bio data.
9. For 'diet', 'exercises', 'lifestyle', and 'supplements', you MUST return data in a strict 3-column pipe-separated format: 'Item | Metric | Personal Justification'. 
   - Column 1 (Item): The specific name of the food, exercise, or habit.
   - Column 2 (Metric): The specific numeric value (e.g., '180g', '4 sets x 10 reps', '20 mins').
   - Column 3 (Personal Justification): A 1-2 line explanation of why this specific item was chosen based on the user's bio-data (age, weight, injuries, or goals).
   - IMPORTANT: Each entry must be on its own line. Do NOT use bullet points (•) or dashes (-).
   - ALWAYS STRICTLY FOLLOW: give 3-4 rows for diet, 6-7 rows for exercise,3-4 rows for lifestyle,2-3 rows for supplements, 2-3 rows for motivation, 2-3 rows for tracking progress.
{
  "diet": "Meal/Food | Macro/Qty | Justification based on user data\n",
  "exercises": "Exercise | Sets/Reps | Justification based on user data\n",
  "lifestyle": "Habit | Frequency | Justification based on user data\n",
  "supplements": "Supplement | Dosage | Justification based on bio-data\n",
  "target_calories": integer,
  "target_steps": integer,
  "target_sleep": integer,
  "target_gym_mins": integer,
  "target_yoga_mins": integer,
  "target_sports_mins": integer,
  "target_weight": $targetWeight,
  "current_body_fat": double,
  "target_body_fat": $targetBodyFat,
  "estimated_weeks": double,
  "motivation": "Type | Metric | Description\n",
  "tracking": "Type | Metric | Description\n"
}
""";

    final body = {
      "contents": [{"parts": [{"text": prompt}]}]
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data["candidates"][0]["content"]["parts"][0]["text"];
      int firstBracket = text.indexOf('{');
      int lastBracket = text.lastIndexOf('}');
      if (firstBracket != -1 && lastBracket != -1) {
        text = text.substring(firstBracket, lastBracket + 1);
      }
      return jsonDecode(text);
    } else {
      throw Exception("Failed to generate plan");
    }
  }
}
