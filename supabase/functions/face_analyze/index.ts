import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { image } = await req.json()
    if (!image) throw new Error('Image data is required')

    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) throw new Error('GEMINI_API_KEY is not set')

    // --- PERBAIKAN: GANTI KE GEMINI 1.5 PRO ---
    // Model ini lebih stabil dan jarang kena error 404 dibanding Flash
    const model = 'gemini-1.5-pro';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: `Analyze this face. Return JSON with 3 keys: 1. "gender" (Laki-laki/Perempuan), 2. "age_range" (e.g. "20-25 tahun"), 3. "ethnicity" (e.g. "Asia Tenggara"). RAW JSON ONLY.` },
            { inline_data: { mime_type: "image/jpeg", data: image } }
          ]
        }]
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      // Log error biar jelas
      console.error("Gemini API Error:", errText);
      throw new Error(`Google API Error (${response.status}): ${errText}`);
    }

    const data = await response.json();
    let resultText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (!resultText) throw new Error("AI tidak memberikan jawaban.");

    // Bersihkan Markdown
    resultText = resultText.replace(/```json/g, '').replace(/```/g, '').trim();
    
    return new Response(JSON.stringify(JSON.parse(resultText)), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})