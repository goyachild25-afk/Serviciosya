// Edge Function: send-notification
// Envía push notifications via Firebase Cloud Messaging (FCM v1 API).
//
// Variables de entorno necesarias (Supabase Dashboard → Edge Functions → Secrets):
//   FCM_PROJECT_ID    — Firebase Project ID
//   FCM_SERVICE_KEY   — Service Account Key (JSON completo, base64-encoded)
//                       Firebase Console → Project Settings → Service Accounts
//                       → Generate new private key → codificar en base64
//
// Uso:
//   await supabase.functions.invoke('send-notification', {
//     body: {
//       userId: 'uuid-del-receptor',
//       title: 'Nueva reserva',
//       body: 'Ana Rodríguez solicitó Limpieza del hogar',
//       data: { type: 'new_booking', booking_id: 'book-123' }
//     }
//   });

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_URL = `https://fcm.googleapis.com/v1/projects/${Deno.env.get('FCM_PROJECT_ID')}/messages:send`;

Deno.serve(async (req) => {
  const { userId, title, body, data = {} } = await req.json();

  if (!userId || !title) {
    return new Response(JSON.stringify({ error: 'userId and title required' }), {
      status: 400, headers: { 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Obtener todos los tokens FCM del usuario
  const { data: tokens, error } = await supabase
    .from('device_tokens')
    .select('token')
    .eq('user_id', userId);

  if (error || !tokens?.length) {
    return new Response(JSON.stringify({ sent: 0, reason: 'no_tokens' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const accessToken = await getFCMAccessToken();
  let sent = 0;

  for (const { token } of tokens) {
    const res = await fetch(FCM_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
          webpush: {
            notification: {
              title, body,
              icon: '/icons/Icon-192.png',
              badge: '/icons/Icon-192.png',
            },
            fcm_options: { link: '/' },
          },
        },
      }),
    });

    if (res.ok) sent++;
    else {
      const err = await res.json();
      // Token inválido → eliminarlo
      if (err.error?.details?.[0]?.errorCode === 'UNREGISTERED') {
        await supabase.from('device_tokens').delete().eq('token', token);
      }
    }
  }

  return new Response(JSON.stringify({ sent, total: tokens.length }), {
    headers: { 'Content-Type': 'application/json' },
  });
});

async function getFCMAccessToken(): Promise<string> {
  // Decodificar la clave de servicio desde variable de entorno
  const keyJson = JSON.parse(
    new TextDecoder().decode(
      Uint8Array.from(atob(Deno.env.get('FCM_SERVICE_KEY')!), c => c.charCodeAt(0))
    )
  );

  // Crear JWT para OAuth2
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = btoa(JSON.stringify({
    iss: keyJson.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));

  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(keyJson.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign']
  );
  const signature = btoa(String.fromCharCode(
    ...new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(signingInput)))
  ));

  const jwt = `${signingInput}.${signature}`;
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const { access_token } = await tokenRes.json();
  return access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, '');
  return Uint8Array.from(atob(b64), c => c.charCodeAt(0)).buffer;
}
