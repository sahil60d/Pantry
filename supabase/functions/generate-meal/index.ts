import "@supabase/functions-js/edge-runtime.d.ts"

interface GenerateMealRequest {
  ingredients: string[]
}

interface MealPlanResponse {
  title: string
  recipe: string
  missing_ingredients: string[]
}

const SYSTEM_PROMPT = `You are a sports nutritionist AI specializing in fat loss, muscle maintenance, and athletic endurance.

When given a list of available ingredients, generate ONE high-protein, energy-sustaining meal.

You MUST respond with ONLY a valid JSON object — no markdown, no explanation, no text outside the JSON.

Use exactly this format:
{
  "title": "Meal name",
  "recipe": "Step-by-step cooking instructions",
  "missing_ingredients": ["ingredient1", "ingredient2"]
}

The "missing_ingredients" array should list common ingredients that would significantly improve the meal but are not in the provided list. If none are needed, return an empty array.`

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  const apiKey = Deno.env.get("OPENROUTER_API_KEY")
  if (!apiKey) {
    return errorResponse("OpenRouter API key is not configured.", 500)
  }

  let body: GenerateMealRequest
  try {
    body = await req.json()
  } catch {
    return errorResponse("Invalid JSON body.", 400)
  }

  const { ingredients } = body
  if (!ingredients || ingredients.length === 0) {
    return errorResponse("No ingredients provided.", 400)
  }

  const userMessage = `Available ingredients: ${ingredients.join(", ")}. Generate a meal plan.`

  const openRouterRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://github.com/sahil60d/Pantry",
      "X-Title": "Pantry App",
    },
    body: JSON.stringify({
      model: "openrouter/auto",
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userMessage },
      ],
      response_format: { type: "json_object" },
    }),
  })

  if (!openRouterRes.ok) {
    const text = await openRouterRes.text()
    return errorResponse(`OpenRouter error: ${text}`, 502)
  }

  const completion = await openRouterRes.json()
  const content: string | undefined = completion.choices?.[0]?.message?.content

  if (!content) {
    return errorResponse("No content in AI response.", 502)
  }

  let mealPlan: MealPlanResponse
  try {
    mealPlan = JSON.parse(content)
  } catch {
    return errorResponse("AI returned malformed JSON.", 502)
  }

  return new Response(JSON.stringify(mealPlan), {
    headers: { "Content-Type": "application/json" },
  })
})

function errorResponse(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}
