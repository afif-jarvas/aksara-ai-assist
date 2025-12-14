import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    let body;
    try {
        body = await req.json();
    } catch (e) {
        throw new Error("Gagal membaca gambar. Pastikan kompresi Flutter (maxWidth: 500) aktif.");
    }
    
    const { image } = body;
    // ==========================================
    // ⚠️ MASUKKAN TOKEN HF ANDA DI SINI ⚠️
    // ==========================================
    const hfToken = "kepo ya"; 

    if (!hfToken || hfToken.includes("MASUKKAN_TOKEN")) {
        throw new Error("Token HF belum dipasang di index.ts!");
    }

    // 1. Bersihkan Base64 (Hapus header data:image/...)
    let cleanBase64 = image;
    if (image.includes("base64,")) cleanBase64 = image.split("base64,")[1];
    cleanBase64 = cleanBase64.replace(/\s/g, '').replace(/\n/g, '');

    // 2. DAFTAR MODEL & URL (STRATEGI MULTI-NYAWA)
    // Kita pakai URL Router (Baru) sebagai prioritas, dan URL Inference (Lama/Backup)
    const strategies = [
        {
            name: "BLIP Base (Router/Baru)",
            url: "https://router.huggingface.co/hf-inference/models/Salesforce/blip-image-captioning-base"
        },
        {
            name: "Microsoft GIT (Backup)",
            url: "https://api-inference.huggingface.co/models/microsoft/git-base"
        },
        {
            name: "ViT-GPT2 (Cadangan Terakhir)",
            url: "https://api-inference.huggingface.co/models/nlpconnect/vit-gpt2-image-captioning"
        }
    ];

    let finalCaption = "";
    let usedModel = "";
    let logs = "";

    // 3. LOOPING MENCOBA MODEL SATU PER SATU
    for (const strategy of strategies) {
        try {
            console.log(`[FaceScan] Mencoba: ${strategy.name}...`);
            
            const response = await fetch(strategy.url, {
                method: 'POST',
                headers: { 
                    'Authorization': `Bearer ${hfToken}`, 
                    'Content-Type': 'application/json' 
                },
                body: JSON.stringify({ inputs: cleanBase64 })
            });

            // Jika error 410 (Gone) atau 404 (Not Found), lanjut ke model berikutnya
            if (!response.ok) {
                const errDetail = await response.text();
                logs += `| ${strategy.name}: ${response.status} `;
                
                // Jika 503 (Loading), kita berhenti dan minta user menunggu (jangan paksa pindah model)
                if (response.status === 503) {
                     return new Response(JSON.stringify({
                        gender: "AI Loading...",
                        age_range: "Tunggu 10s",
                        ethnicity: "Coba Lagi",
                        note: "Server AI sedang dinyalakan (503). Tekan tombol lagi dalam 10 detik."
                    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
                }
                
                // Lanjut ke loop berikutnya
                continue;
            }

            const result = await response.json();
            
            // Format response HF adalah array: [{ "generated_text": "..." }]
            if (Array.isArray(result) && result[0]?.generated_text) {
                finalCaption = result[0].generated_text.toLowerCase();
                usedModel = strategy.name;
                console.log(`✅ SUKSES pakai ${strategy.name}: "${finalCaption}"`);
                break; // BERHASIL! Keluar dari loop
            } else {
                logs += `| ${strategy.name}: Format Salah `;
            }

        } catch (e) {
            logs += `| ${strategy.name}: Error ${e.message} `;
        }
    }

    // Jika SEMUA model gagal
    if (!finalCaption) {
        throw new Error(`Semua model gagal. Log: ${logs}`);
    }

    // 4. LOGIKA PENERJEMAH (CAPTION -> DATA JSON)
    // Menerjemahkan kalimat bahasa Inggris ke data JSON untuk UI Flutter
    
    let gender = "Laki-laki";
    if (finalCaption.match(/\b(woman|girl|lady|female|she|wife|mother|sister|actress|queen)\b/)) {
        gender = "Perempuan";
    }

    let age_range = "20 - 30 tahun";
    if (finalCaption.match(/\b(child|kid|boy|baby|toddler)\b/)) age_range = "5 - 12 tahun";
    else if (finalCaption.match(/\b(teen|student)\b/)) age_range = "14 - 19 tahun";
    else if (finalCaption.match(/\b(old|senior|elderly|grand)\b/)) age_range = "55 - 75 tahun";
    else if (finalCaption.match(/\b(man|woman|guy|lady)\b/)) age_range = "23 - 35 tahun";

    let ethnicity = "Indonesia";
    if (finalCaption.match(/\b(white|caucasian|blonde)\b/)) ethnicity = "Eropa";
    else if (finalCaption.match(/\b(black|african)\b/)) ethnicity = "Afrika";
    else if (finalCaption.match(/\b(indian)\b/)) ethnicity = "India";
    else if (finalCaption.match(/\b(asian|chinese|korean|japanese)\b/)) ethnicity = "Asia Timur";

    // Kirim response sukses ke Flutter
    return new Response(JSON.stringify({
        gender: gender,
        age_range: age_range,
        ethnicity: ethnicity,
        note: `AI: "${finalCaption}"` // Tampilkan deskripsi asli di note
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (error) {
    // 5. ERROR HANDLING (Tampil di UI, bukan Crash)
    // Tampilkan pesan error di kolom Gender agar terbaca di HP
    return new Response(JSON.stringify({ 
        gender: `Gagal: ${error.message.substring(0, 15)}...`,
        age_range: "-",
        ethnicity: "-",
        note: `ERROR DETAIL: ${error.message}`
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200, // Sengaja 200 biar UI Flutter tetap merender hasil errornya
    })
  }
})