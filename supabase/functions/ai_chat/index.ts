import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const { message, mode, modelType } = await req.json()
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) throw new Error("API Key belum disetting.")

    // 1. TENTUKAN MODEL & GAYA (BEDA DRASTIS)
    let targetModel = "gemini-2.5-flash"; // Default
    let instruction = "";

    if (modelType === 'pro') {
        // MODE PRO: Pakai 2.5 Pro, Jawab Panjang Lebar, Analitis
        targetModel = "gemini-2.5-pro"; 
        instruction = `
        [MODE: PRO / EXPERT]
        1. Jawablah dengan SANGAT LENGKAP, DETAIL, dan MENDALAM.
        2. Minimal 3 paragraf. Jelaskan konsep, alasan, dan contoh.
        3. Gunakan gaya bahasa akademis yang cerdas tapi mudah dimengerti.
        4. Anggap kamu sedang mengajari mahasiswa di kelas.
        `;
        // Simulasi berpikir (Delay)
        await new Promise(r => setTimeout(r, 1500)); 
    } else {
        // MODE FLASH: Pakai 2.5 Flash, Jawab Singkat
        targetModel = "gemini-2.5-flash";
        instruction = `
        [MODE: FLASH / FAST]
        1. Jawablah dengan SINGKAT dan PADAT (Maksimal 2-3 kalimat).
        2. Langsung ke inti masalah. Jangan bertele-tele.
        3. Gaya bahasa santai dan cepat.
        `;
    }

    // 2. SYSTEM PROMPT
    const systemPrompt = `
    IDENTITAS:
    - Nama: Aksara AI.
    - Pencipta: Tim Mahasiswa PNJ BM 5B (Muhammad Febryadi [NIM 2303421027], Ananda Afif Fauzan [NIM 2303421025], Lintang Dyahayuningsih [NIM 2303421038]).
    
    ATURAN FORMAT:
    - JANGAN pakai Markdown (**bold**). Teks polos saja.
    - Gunakan Emoji secukupnya.
    
    ${instruction}
    `;

    // 3. PANGGIL API
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${targetModel}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `${systemPrompt}\n\nUser: ${message}` }] }]
        })
      }
    );

    const data = await response.json();

    if (data.error) {
        // Fallback jika model spesifik error
        throw new Error(data.error.message);
    }

    let reply = data.candidates?.[0]?.content?.parts?.[0]?.text || "Maaf, error.";
    reply = reply.replace(/\*\*/g, "").replace(/\*/g, "").replace(/#/g, "");

    return new Response(
      JSON.stringify({ text: reply, model: modelType }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ text: `Maaf, server sibuk: ${error.message}` }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } },
    )
  }
})