import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ChatRequest {
  message: string;
  user_id: string;
}

interface ChatResponse {
  text: string;
  action?: {
    type: string;
    params?: Record<string, any>;
  };
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { message, user_id }: ChatRequest = await req.json();

    // Mock LLM processing (replace with actual LLM API call)
    const response: ChatResponse = await processLLM(message, user_id);

    // Publish to Realtime channel
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

async function processLLM(
  message: string,
  userId: string
): Promise<ChatResponse> {
  // Mock LLM response - Replace with actual LLM API (OpenAI, Anthropic, etc.)
  const lowerMessage = message.toLowerCase();

  // Command detection
  if (lowerMessage.includes("scan qr") || lowerMessage.includes("buka scanner")) {
    return {
      text: "Baik, saya akan membuka QR scanner untuk Anda.",
      action: {
        type: "scan_qr",
      },
    };
  }

  if (lowerMessage.includes("ambil foto") || lowerMessage.includes("foto")) {
    return {
      text: "Membuka kamera untuk mengambil foto.",
      action: {
        type: "take_photo",
      },
    };
  }

  // Default response
  return {
    text: `Saya memahami: "${message}". Ini adalah respons dari AI Assistant. Untuk implementasi penuh, hubungkan ke LLM API seperti OpenAI atau Anthropic.`,
  };
}
