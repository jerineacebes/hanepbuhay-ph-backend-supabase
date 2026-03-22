# API Contracts Reference

## create-chat-session
- **Method:** POST
- **Request:** {}
- **Response:** `ChatSession` object

## add-chat-message
- **Method:** POST
- **Request:** `{ "session_id": "uuid", "content": "text" }`
- **Response:** `{ "userMessage": message, "botMessage": message }`

## extract-worker-profile
- **Method:** POST
- **Request:** `{ "session_id": "uuid" }`
- **Response:** `{ "success": true, "extractedData": { "summary": "...", "skills": [], ... } }`

## rank-candidates-for-job
- **Method:** POST
- **Request:** `{ "job_id": "uuid" }`
- **Response:** `Array<{ job_seeker_id, full_name, total_score, score_breakdown }>`

## RPC: route_candidate
- **Method:** RPC (via supabase.rpc)
- **Request:** `{ "p_job_seeker_id": "uuid" }`
- **Response:** `{ "decision": "...", "reasons": [], "explanation": "..." }`
