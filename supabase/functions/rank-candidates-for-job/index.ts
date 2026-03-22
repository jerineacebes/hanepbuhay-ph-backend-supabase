import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient } from '../_shared/supabaseClient.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createSupabaseClient(req);
    const { job_id } = await req.json();

    if (!job_id) throw new Error('Missing job_id');

    const { data, error } = await supabaseClient.rpc('rank_candidates_for_job', { p_job_id: job_id });

    if (error) throw error;

    // Cache results or additional processing could go here
    for (const match of data) {
      await supabaseClient.from('candidate_matches').upsert({
        job_id,
        job_seeker_id: match.job_seeker_id,
        total_score: match.total_score,
        score_breakdown: match.score_breakdown
      });
    }

    return new Response(JSON.stringify(data), {
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
