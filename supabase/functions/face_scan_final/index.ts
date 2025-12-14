import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Fungsi darurat untuk memperbaiki JSON yang terpotong
function tryRepairJson(jsonStr) {
    jsonStr = jsonStr.trim();
    
    // Coba 1: Tambahkan kurung tutup biasa
    try { return JSON.parse(jsonStr + "}"); } catch (e) {}
    
    // Coba 2: Tambahkan petik dan kurung tutup (jika terpotong di tengah string)
    try { return JSON.parse(jsonStr + "\"}"); } catch (e) {}
    
    // Coba 3: Kasus array
    try { return JSON.parse(jsonStr + "]"); } catch (e) {}
    try { return JSON.parse(jsonStr + "}]"); } catch (e) {}

    // Menyerah
    return null;
}

serve(async (req) => {
  console.log(`🚀 [FaceScan] Request received: ${req.method}`);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    let body;
    try {
        body = await req.json();
    } catch (e) {
        throw new Error("Gagal membaca body request. Pastikan format JSON benar.");
    }
    
    const { image } = body;

    if (!image) {
        throw new Error("Parameter 'image' tidak dikirim!");
    }

    // ==========================================
    // ⚠️ MASUKKAN API KEY GEMINI ANDA DI SINI ⚠️
    // ==========================================
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY') || "MASUKKAN_KEY_GEMINI_DISINI"; 

    if (!geminiApiKey || geminiApiKey.includes("MASUKKAN_KEY")) {
        throw new Error("API Key Gemini belum diset!");
    }

    // 1. Bersihkan Base64
    let cleanBase64 = image;
    if (image.includes("base64,")) {
        cleanBase64 = image.split("base64,")[1];
    }
    cleanBase64 = cleanBase64.replace(/\s/g, '').replace(/\n/g, '');

    // 2. Persiapkan Prompt
    const promptText = `
      You are a face analysis API. Output ONLY valid JSON.
      
      Analyze the image and return this JSON structure:
      {
        "gender": "Laki-laki" or "Perempuan",
        "age_range": "e.g. 20 - 25 tahun",
        "ethnicity": "Indonesia" (or other detected ethnicity),
        "note": "Short description in Bahasa Indonesia (max 1 sentence)"
      }
    `;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`;
    
    console.log("📡 [FaceScan] Mengirim request ke Gemini 2.5 Flash... (Waiting)");
    const startTime = Date.now();

    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            contents: [{
                parts: [
                    { text: promptText },
                    { inline_data: { mime_type: "image/jpeg", data: cleanBase64 } }
                ]
            }],
            generationConfig: {
                temperature: 0.4,
                maxOutputTokens: 1024, // Cukup untuk JSON kecil
                responseMimeType: "application/json"
            }
        })
    });

    const endTime = Date.now();
    console.log(`⏱️ [FaceScan] Gemini merespon dalam ${endTime - startTime}ms. Status: ${response.status}`);

    if (!response.ok) {
        const errText = await response.text();
        throw new Error(`Gemini API Error: ${response.status} - ${errText}`);
    }

    const result = await response.json();
    const rawText = result.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
        throw new Error("Gemini tidak memberikan respons teks.");
    }

    console.log("📝 [FaceScan] Raw AI:", rawText.substring(0, 150) + "..."); 

    // 3. Parsing JSON (Dengan Fitur Auto-Repair)
    let parsedData;
    try {
        let jsonStr = rawText.trim();
        
        // Coba bersihkan markdown ```json jika ada
        if (jsonStr.startsWith("```json")) {
            jsonStr = jsonStr.replace(/^```json/, "").replace(/```$/, "").trim();
        }

        try {
            parsedData = JSON.parse(jsonStr);
            console.log("✅ [FaceScan] Parsing JSON Sukses (Normal).");
        } catch (originalError) {
            console.warn("⚠️ [FaceScan] Parsing Normal Gagal, mencoba Auto-Repair...");
            
            // Coba perbaiki JSON yang terpotong
            parsedData = tryRepairJson(jsonStr);
            
            if (parsedData) {
                console.log("🔧 [FaceScan] SUKSES! JSON berhasil diperbaiki otomatis.");
            } else {
                // Jika masih gagal, cari kurung kurawal manual (sebagai upaya terakhir)
                const firstBrace = jsonStr.indexOf('{');
                const lastBrace = jsonStr.lastIndexOf('}');
                
                if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
                     const extracted = jsonStr.substring(firstBrace, lastBrace + 1);
                     parsedData = JSON.parse(extracted);
                     console.log("✅ [FaceScan] Parsing Sukses (Extracted).");
                } else {
                    throw originalError; // Lempar error asli jika semua cara gagal
                }
            }
        }

    } catch (e) {
        console.error("❌ [FaceScan] JSON Parse Fatal Error. String:", rawText);
        throw new Error("Format data AI rusak dan tidak bisa diperbaiki.");
    }

    // 4. Validasi & Default Values
    const finalGender = parsedData.gender || "Laki-laki";
    const finalAge = parsedData.age_range || "20 - 30 tahun";
    const finalEthnicity = parsedData.ethnicity || "Indonesia";
    const finalNote = parsedData.note || "Wajah terdeteksi.";

    return new Response(JSON.stringify({
        gender: finalGender,
        age_range: finalAge,
        ethnicity: finalEthnicity,
        note: `AI: ${finalNote}`
    }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    });

  } catch (error) {
    console.error("🔥 [FaceScan] CRITICAL ERROR:", error.message);
    
    return new Response(JSON.stringify({ 
        gender: "Gagal",
        age_range: "-",
        ethnicity: "-",
        note: `Error: ${error.message}`
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200, 
    })
  }
})