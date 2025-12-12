import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// 1. UPDATE INTERFACE
// Kita tambahkan 'modelType' agar bisa switch antara Fast/Expert
interface ChatRequest {
  message: string;
  user_id: string;
  modelType?: string; // 'fast' atau 'expert'
}

interface ChatResponse {
  text: string;
  action?: {
    type: string;
    params?: Record<string, any>;
  };
}

Deno.serve(async (req) => {
  // 2. HANDLE CORS (Wajib untuk Flutter)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 3. SETUP SUPABASE CLIENT
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // 4. AMBIL DATA DARI FLUTTER
    const { message, user_id, modelType } = await req.json();

    // 5. PROSES LOGIKA (FUSION: Cek Command Dulu -> Kalau Gak Ada, Tanya Gemini)
    const response: ChatResponse = await processLLM(message, user_id, modelType);

    // 6. KIRIM KE REALTIME (Agar chat muncul live/broadcast ke user lain jika perlu)
    await supabaseClient.channel("ai_chat").send({
      type: "broadcast",
      event: "assistant_response",
      payload: {
        user_id,
        message,
        response: response.text,
        timestamp: new Date().toISOString(),
      },
    });

    // 7. BALAS KE FLUTTER
    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});

// --- FUNGSI OTAK (FUSION LOGIC) ---
async function processLLM(
  message: string,
  userId: string,
  modelType: string = 'fast' // Default ke fast kalau tidak dikirim
): Promise<ChatResponse> {
  
  const lowerMessage = message.toLowerCase();

  // === BAGIAN 1: DETEKSI PERINTAH LOKAL (SCAN QR / FOTO) ===
  // Ini dari kodemu yang lama. Kita prioritaskan ini agar cepat.
  
  if (lowerMessage.includes("scan qr") || lowerMessage.includes("buka scanner")) {
    return {
      text: "Baik, aku bukain scanner QR-nya ya!",
      action: { type: "scan_qr" },
    };
  }

  if (lowerMessage.includes("ambil foto") || lowerMessage.includes("buka kamera")) {
    return {
      text: "Siap, aku buka kameranya sekarang.",
      action: { type: "take_photo" },
    };
  }

  // === BAGIAN 2: HIT KE GEMINI 2.5 (PENGGANTI MOCK) ===
  // Kalau bukan perintah QR/Foto, kita lempar ke AI Google.
  
  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) throw new Error("API Key belum disetting di Supabase Secrets.");

    // Tentukan Model sesuai Request (Paksa 2.5)
    let targetModel = "gemini-2.5-flash"; 
    let systemInstruction = "Jawab singkat, padat, gaya gaul (aku-kamu).";

    if (modelType === 'expert') {
        targetModel = "gemini-2.5-pro";
        systemInstruction = "Jawab mendalam, lengkap, minimal 3 paragraf. Gaya tetap santai.";
    }

    // Persona Aksara AI
    const prompt = `
    [IDENTITAS]
    Nama: Aksara AI.
    Karakter: Asisten mahasiswa yang asik, ramah, gaul, dan suportif.
    
    [INSTRUKSI]
    ${systemInstruction}

    [PERTANYAAN USER]
    ${message}
    
    Jawablah sebagai Aksara AI (tanpa format bold berlebihan):
    `;

    // Fetch ke Google
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${targetModel}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }]
        })
      }
    );

    const data = await res.json();

    if (data.error) {
      // Fallback kalau model 2.5 error, beri pesan jelas
      console.error("Gemini Error:", data.error);
      return { 
        text: `Waduh, server Google lagi ngambek nih (Error: ${data.error.message}). Coba lagi nanti ya!` 
      };
    }

    let aiReply = data.candidates?.[0]?.content?.parts?.[0]?.text || "Maaf, aku lagi loading lama banget.";
    
    // Bersihkan format markdown bold (**) biar rapi di HP
    aiReply = aiReply.replace(/\*\*/g, ""); 

    return {
      text: aiReply
    };

  } catch (err) {
    return {
      text: `Ada kesalahan sistem di server: ${err.message}`
    };
  }
}