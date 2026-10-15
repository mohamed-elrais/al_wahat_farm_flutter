// Photo storage on Cloudflare R2 (R2_PHOTOS_PLAN.md), served by the Pages
// Function in functions/api/photos/[[route]].js on the app's own site.
//
//   PUT    /api/photos/object/<path>   upload (your own folder only)
//   DELETE /api/photos/object/<path>   delete (your own folder only)
//   POST   /api/photos/sign            {paths: [...]} -> {urls: {path: url}}
//   GET    /api/photos/file/<path>?e=&s=   a signed link from /sign
//
// Uploads, deletes and signing need the user's Supabase login token. The
// database decides what the user may do (public.photo_path_access), with the
// same rules as the farm-evidence storage policies. Photos that are not in R2
// (uploaded before the move) get a Supabase signed link made with the user's
// own token, so Supabase's rules still apply to them.
//
// env: PHOTOS (R2 bucket binding), SUPABASE_URL, SUPABASE_ANON_KEY,
// PHOTO_URL_SECRET (signs the /file links).

export const MAX_BYTES = 10 * 1024 * 1024;
export const MAX_PATHS = 100;
const SUPABASE_BUCKET = 'farm-evidence';
const HOUR = 3600;
const SEGMENT = /^[A-Za-z0-9._-]{1,200}$/;
// The first bytes of each accepted image type.
const SIGNATURES = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47],
  'image/webp': [0x52, 0x49, 0x46, 0x46],
};

class HttpError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

export async function handlePhotoRequest(request, env, deps = {}) {
  const now = deps.now ?? Date.now();
  const fetcher = deps.fetch ?? fetch;
  const url = new URL(request.url);
  const route = url.pathname.replace(/^\/api\/photos\/?/, '');
  try {
    if (route === 'sign' && request.method === 'POST') {
      return await sign(request, env, url, now, fetcher);
    }
    if (route.startsWith('file/')) {
      if (request.method !== 'GET' && request.method !== 'HEAD') {
        throw new HttpError(405, 'method_not_allowed');
      }
      return await serveFile(request, env, url, route.slice(5), now);
    }
    if (route.startsWith('object/')) {
      const path = parsePath(route.slice(7));
      if (request.method === 'PUT') {
        return await upload(request, env, path, fetcher);
      }
      if (request.method === 'DELETE') {
        return await remove(request, env, path, fetcher);
      }
      throw new HttpError(405, 'method_not_allowed');
    }
    throw new HttpError(404, 'not_found');
  } catch (error) {
    if (error instanceof HttpError) {
      return json({ error: error.code }, error.status);
    }
    console.error('photos', error);
    return json({ error: 'server_error' }, 500);
  }
}

// Splits and checks a storage path such as `user/farm/task/123_photo.jpg`.
export function parsePath(raw) {
  let segments;
  try {
    segments = raw.split('/').map((part) => decodeURIComponent(part));
  } catch {
    throw new HttpError(400, 'bad_path');
  }
  if (
    segments.length < 2 ||
    segments.length > 8 ||
    segments.some((part) => !SEGMENT.test(part) || /^\.+$/.test(part))
  ) {
    throw new HttpError(400, 'bad_path');
  }
  return segments.join('/');
}

function requireConfig(env) {
  if (
    !env.PHOTOS ||
    !env.SUPABASE_URL ||
    !env.SUPABASE_ANON_KEY ||
    !env.PHOTO_URL_SECRET
  ) {
    throw new HttpError(500, 'not_configured');
  }
}

function bearer(request) {
  const header = request.headers.get('Authorization') ?? '';
  const match = /^Bearer\s+(\S+)$/i.exec(header);
  if (!match) throw new HttpError(401, 'unauthorized');
  return match[1];
}

// What the signed-in user may do with each path, from the database.
async function access(env, token, paths, fetcher) {
  const response = await fetcher(
    `${env.SUPABASE_URL}/rest/v1/rpc/photo_path_access`,
    {
      method: 'POST',
      headers: {
        apikey: env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_paths: paths }),
    },
  );
  if (response.status === 401) throw new HttpError(401, 'unauthorized');
  // 42501: signed out (no user in the token).
  if (response.status === 403) throw new HttpError(401, 'unauthorized');
  if (!response.ok) throw new HttpError(502, 'access_check_failed');
  const rows = await response.json();
  const result = new Map();
  for (const row of rows) {
    result.set(row.path, {
      canView: row.can_view === true,
      canWrite: row.can_write === true,
    });
  }
  return result;
}

async function upload(request, env, path, fetcher) {
  requireConfig(env);
  const token = bearer(request);
  const contentType = (request.headers.get('Content-Type') ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  const signature = SIGNATURES[contentType];
  if (!signature) throw new HttpError(415, 'unsupported_type');
  const declared = Number(request.headers.get('Content-Length') ?? '0');
  if (declared > MAX_BYTES) throw new HttpError(413, 'too_large');

  const rights = (await access(env, token, [path], fetcher)).get(path);
  if (!rights?.canWrite) throw new HttpError(403, 'forbidden');

  const body = new Uint8Array(await request.arrayBuffer());
  if (body.length === 0) throw new HttpError(400, 'empty');
  if (body.length > MAX_BYTES) throw new HttpError(413, 'too_large');
  if (!signature.every((byte, index) => body[index] === byte)) {
    throw new HttpError(415, 'unsupported_type');
  }
  // A retry of the same upload rewrites the same file in the user's folder.
  await env.PHOTOS.put(path, body, { httpMetadata: { contentType } });
  return json({ path }, 201);
}

async function remove(request, env, path, fetcher) {
  requireConfig(env);
  const token = bearer(request);
  const rights = (await access(env, token, [path], fetcher)).get(path);
  if (!rights?.canWrite) throw new HttpError(403, 'forbidden');

  if (await env.PHOTOS.head(path)) {
    await env.PHOTOS.delete(path);
  } else {
    // An older photo still in Supabase storage; its policies apply.
    const response = await fetcher(
      `${env.SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}`,
      {
        method: 'DELETE',
        headers: {
          apikey: env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prefixes: [path] }),
      },
    );
    if (!response.ok) throw new HttpError(502, 'delete_failed');
  }
  return json({ deleted: path }, 200);
}

async function sign(request, env, url, now, fetcher) {
  requireConfig(env);
  const token = bearer(request);
  let body;
  try {
    body = await request.json();
  } catch {
    throw new HttpError(400, 'bad_request');
  }
  if (!Array.isArray(body?.paths) || body.paths.length === 0) {
    throw new HttpError(400, 'bad_request');
  }
  if (body.paths.length > MAX_PATHS) throw new HttpError(400, 'too_many');
  const paths = [
    ...new Set(
      body.paths.map((path) => {
        if (typeof path !== 'string') throw new HttpError(400, 'bad_path');
        return parsePath(path);
      }),
    ),
  ];

  const rights = await access(env, token, paths, fetcher);
  const viewable = paths.filter((path) => rights.get(path)?.canView);
  const inR2 = await Promise.all(
    viewable.map(async (path) => (await env.PHOTOS.head(path)) !== null),
  );

  // Links end on the next-but-one full hour, so a photo asked for twice in
  // the same hour gets the same link and the browser can reuse its copy.
  const expires = (Math.floor(now / 1000 / HOUR) + 2) * HOUR;
  const urls = {};
  const older = [];
  for (const [index, path] of viewable.entries()) {
    if (inR2[index]) {
      const signature = await hmac(env.PHOTO_URL_SECRET, `${path}\n${expires}`);
      urls[path] =
        `${url.origin}/api/photos/file/${path}?e=${expires}&s=${signature}`;
    } else {
      older.push(path);
    }
  }
  if (older.length > 0) {
    Object.assign(urls, await supabaseLinks(env, token, older, fetcher));
  }
  return json({ urls }, 200);
}

async function supabaseLinks(env, token, paths, fetcher) {
  const response = await fetcher(
    `${env.SUPABASE_URL}/storage/v1/object/sign/${SUPABASE_BUCKET}`,
    {
      method: 'POST',
      headers: {
        apikey: env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ expiresIn: HOUR, paths }),
    },
  );
  if (!response.ok) return {};
  const urls = {};
  for (const row of await response.json()) {
    if (row.signedURL && !row.error) {
      urls[row.path] = `${env.SUPABASE_URL}/storage/v1${row.signedURL}`;
    }
  }
  return urls;
}

async function serveFile(request, env, url, rawPath, now) {
  requireConfig(env);
  const path = parsePath(rawPath);
  const expires = Number(url.searchParams.get('e'));
  const signature = url.searchParams.get('s') ?? '';
  const seconds = Math.floor(now / 1000);
  if (
    !Number.isInteger(expires) ||
    expires <= seconds ||
    expires > seconds + 2 * HOUR + 60 ||
    !(await verifyHmac(env.PHOTO_URL_SECRET, `${path}\n${expires}`, signature))
  ) {
    throw new HttpError(403, 'link_expired_or_invalid');
  }
  const object =
    request.method === 'HEAD'
      ? await env.PHOTOS.head(path)
      : await env.PHOTOS.get(path);
  if (!object) throw new HttpError(404, 'not_found');
  const headers = new Headers({
    'Content-Type': object.httpMetadata?.contentType ?? 'image/jpeg',
    'Cache-Control': `private, max-age=${expires - seconds}`,
    'X-Content-Type-Options': 'nosniff',
    ETag: object.httpEtag,
  });
  return new Response(request.method === 'HEAD' ? null : object.body, {
    status: 200,
    headers,
  });
}

async function hmacKey(secret) {
  return crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
}

export async function hmac(secret, message) {
  const bytes = await crypto.subtle.sign(
    'HMAC',
    await hmacKey(secret),
    new TextEncoder().encode(message),
  );
  return base64url(new Uint8Array(bytes));
}

async function verifyHmac(secret, message, signature) {
  let bytes;
  try {
    bytes = fromBase64url(signature);
  } catch {
    return false;
  }
  return crypto.subtle.verify(
    'HMAC',
    await hmacKey(secret),
    bytes,
    new TextEncoder().encode(message),
  );
}

function base64url(bytes) {
  let text = '';
  for (const byte of bytes) text += String.fromCharCode(byte);
  return btoa(text).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function fromBase64url(value) {
  const text = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(text, (char) => char.charCodeAt(0));
}

function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
    },
  });
}
