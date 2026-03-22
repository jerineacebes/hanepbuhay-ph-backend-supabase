import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, supabaseAdmin } from '../_shared/supabaseClient.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createSupabaseClient(req);
    const { session_id } = await req.json();

    if (!session_id) throw new Error('Missing session_id');

    // 1. Get session and user
    const { data: session, error: sessionError } = await supabaseClient
      .from('chat_sessions')
      .select('job_seeker_id')
      .eq('id', session_id)
      .single();

    if (sessionError) throw sessionError;

    // 2. Get all messages for transcript
    const { data: messages, error: messagesError } = await supabaseClient
      .from('chat_messages')
      .select('sender_type, content')
      .eq('session_id', session_id)
      .order('created_at', { ascending: true });

    if (messagesError) throw messagesError;

    const transcript = messages.map(m => `${m.sender_type}: ${m.content}`).join('\n');

    // 3. Mock AI Extraction Logic
    // In a real app, this would call an OpenAI/Anthropic/Gemini API
    const extractedData = {
      summary: "Worker from Manila with 3 years experience in construction.",
      skills: ["construction", "heavy lifting", "carpentry"],
      experience_years: 3,
      location_text: "Quezon City, Manila",
      preferred_roles: ["Construction Worker", "Foreman"],
      availability_status: "available"
    };

    // 4. Update Job Seeker Profile
    const { error: updateError } = await supabaseAdmin
      .from('job_seekers')
      .update({
        summary: extractedData.summary,
        skills: extractedData.skills,
        experience_years: extractedData.experience_years,
        location_text: extractedData.location_text,
        preferred_roles: extractedData.preferred_roles,
        availability_status: extractedData.availability_status
      })
      .eq('id', session.job_seeker_id);

    if (updateError) throw updateError;

    // 5. Log Extraction
    await supabaseAdmin
      .from('profile_extractions')
      .insert({
        job_seeker_id: session.job_seeker_id,
        session_id: session_id,
        raw_payload: { transcript },
        extracted_data: extractedData
      });

    return new Response(JSON.stringify({ success: true, extractedData }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
