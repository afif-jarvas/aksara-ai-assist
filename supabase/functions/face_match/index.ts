import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface FaceMatchRequest {
  embedding: number[];
}

interface FaceMatchResponse {
  matched: boolean;
  person_name?: string;
  similarity?: number;
  person_id?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { embedding }: FaceMatchRequest = await req.json();

    // Match face using pgvector cosine similarity
    const matchResult = await matchFace(supabaseClient, embedding);

    return new Response(JSON.stringify(matchResult), {
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

async function matchFace(
  supabase: any,
  embedding: number[]
): Promise<FaceMatchResponse> {
  try {
    // Query using pgvector cosine similarity
    // Assuming you have a table 'face_embeddings' with:
    // - id (uuid)
    // - person_name (text)
    // - embedding (vector(128))
    // - created_at (timestamp)

    const { data, error } = await supabase.rpc("match_face_embedding", {
      query_embedding: embedding,
      match_threshold: 0.7, // cosine similarity threshold
      match_count: 1,
    });

    if (error) {
      console.error("Face matching error:", error);
      // Fallback to mock response
      return {
        matched: false,
      };
    }

    if (data && data.length > 0) {
      const match = data[0];
      return {
        matched: true,
        person_name: match.person_name,
        similarity: match.similarity,
        person_id: match.id,
      };
    }

    return {
      matched: false,
    };
  } catch (error) {
    console.error("Face matching error:", error);
    // Mock response for POC
    return {
      matched: false,
    };
  }
}


