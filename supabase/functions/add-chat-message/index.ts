import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient } from '../_shared/supabaseClient.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createSupabaseClient(req);
    const { session_id, content } = await req.json();

    if (!session_id || !content) throw new Error('Missing session_id or content');

    // 1. Save user message
    const { data: userMsg, error: userError } = await supabaseClient
      .from('chat_messages')
      .insert({ session_id, sender_type: 'user', content })
      .select()
      .single();

    if (userError) throw userError;

    // 2. Mock Bot Response
    const botReplies = [
      "Salamat! Maaari mo bang sabihin kung ilang taon na ang iyong karanasan sa trabaho?",
      "Noted. Mayroon ka bang NBI clearance o health card?",
      "Salamat sa impormasyon. Saan ka nakatira ngayon?",
      "Sige, nakuha ko na ang iyong detalye. Hintayin lamang ang aming pagsusuri."
    ];
    const randomReply = botReplies[Math.floor(Math.random() * botReplies.length)];

    const { data: botMsg, error: botError } = await supabaseClient
      .from('chat_messages')
      .insert({ session_id, sender_type: 'bot', content: randomReply })
      .select()
      .single();

    if (botError) throw botError;

    return new Response(JSON.stringify({ userMessage: userMsg, botMessage: botMsg }), {
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
