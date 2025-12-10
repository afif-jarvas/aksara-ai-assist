-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create face_embeddings table
CREATE TABLE face_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_name TEXT NOT NULL,
  embedding vector(128),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for similarity search
CREATE INDEX ON face_embeddings USING ivfflat (embedding vector_cosine_ops);

-- Create function for face matching
CREATE OR REPLACE FUNCTION match_face_embedding(
  query_embedding vector(128),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  person_name text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    face_embeddings.id,
    face_embeddings.person_name,
    1 - (face_embeddings.embedding <=> query_embedding) as similarity
  FROM face_embeddings
  WHERE 1 - (face_embeddings.embedding <=> query_embedding) > match_threshold
  ORDER BY face_embeddings.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON face_embeddings TO anon, authenticated;


