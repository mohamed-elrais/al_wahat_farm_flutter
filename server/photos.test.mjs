// node --test server/photos.test.mjs
import assert from 'node:assert/strict';
import test from 'node:test';

import { handlePhotoRequest, hmac, MAX_BYTES } from './photos.mjs';

const ME = '11111111-1111-1111-1111-111111111111';
const OTHER = '22222222-2222-2222-2222-222222222222';
const MINE = `${ME}/farm/task/1_photo.jpg`;
const THEIRS = `${OTHER}/farm/task/2_photo.jpg`;
const OLD = `${OTHER}/farm/task/0_old.jpg`;
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const NOW = Date.UTC(2026, 9, 15, 10, 30);

class FakeBucket {
  constructor() {
    this.objects = new Map();
  }
  async put(key, body, options) {
    this.objects.set(key, {
      bytes: new Uint8Array(body),
      contentType: options.httpMetadata.contentType,
    });
  }
  async head(key) {
    const object = this.objects.get(key);
    return object ? this.#meta(object) : null;
  }
  async get(key) {
    const object = this.objects.get(key);
    return object
      ? { ...this.#meta(object), body: new Blob([object.bytes]).stream() }
      : null;
  }
  async delete(key) {
    this.objects.delete(key);
  }
  #meta(object) {
    return {
      size: object.bytes.length,
      httpEtag: '"etag"',
      httpMetadata: { contentType: object.contentType },
    };
  }
}

// Supabase stand-in: the "good" token is ME; viewing OTHER's photos is
// allowed only for THEIRS and OLD (as if they were on a task I can see).
function fakeSupabase() {
  const calls = [];
  const fetcher = async (url, init) => {
    calls.push({ url, init });
    if (init.headers.Authorization !== 'Bearer good') {
      return new Response('{}', { status: 401 });
    }
    const body = JSON.parse(init.body);
    if (url.endsWith('/rest/v1/rpc/photo_path_access')) {
      return Response.json(
        body.p_paths.map((path) => ({
          path,
          can_view: path.startsWith(`${ME}/`) || path === THEIRS || path === OLD,
          can_write: path.startsWith(`${ME}/`),
        })),
      );
    }
    if (url.endsWith('/storage/v1/object/sign/farm-evidence')) {
      return Response.json(
        body.paths.map((path) => ({
          path,
          signedURL: `/object/sign/farm-evidence/${path}?token=t`,
          error: null,
        })),
      );
    }
    if (url.endsWith('/storage/v1/object/farm-evidence')) {
      return Response.json([]);
    }
    return new Response('{}', { status: 404 });
  };
  return { calls, fetcher };
}

function setup() {
  const supabase = fakeSupabase();
  const env = {
    PHOTOS: new FakeBucket(),
    SUPABASE_URL: 'https://db.example',
    SUPABASE_ANON_KEY: 'anon',
    PHOTO_URL_SECRET: 'secret',
  };
  const call = (method, path, { token = 'good', body, type, now = NOW } = {}) =>
    handlePhotoRequest(
      new Request(`https://farm.example/api/photos/${path}`, {
        method,
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          ...(type ? { 'Content-Type': type } : {}),
        },
        body,
      }),
      env,
      { now, fetch: supabase.fetcher },
    );
  return { env, call, calls: supabase.calls };
}

test('uploads a JPEG into your own folder', async () => {
  const { env, call } = setup();
  const response = await call('PUT', `object/${MINE}`, {
    body: JPEG,
    type: 'image/jpeg',
  });
  assert.equal(response.status, 201);
  assert.deepEqual(await response.json(), { path: MINE });
  assert.deepEqual(env.PHOTOS.objects.get(MINE).bytes, JPEG);
});

test("refuses uploads into someone else's folder", async () => {
  const { env, call } = setup();
  const response = await call('PUT', `object/${THEIRS}`, {
    body: JPEG,
    type: 'image/jpeg',
  });
  assert.equal(response.status, 403);
  assert.equal(env.PHOTOS.objects.size, 0);
});

test('needs a valid login token', async () => {
  const { call } = setup();
  assert.equal(
    (await call('PUT', `object/${MINE}`, { body: JPEG, type: 'image/jpeg', token: null })).status,
    401,
  );
  assert.equal(
    (await call('PUT', `object/${MINE}`, { body: JPEG, type: 'image/jpeg', token: 'expired' })).status,
    401,
  );
});

test('only accepts real images up to 10 MiB', async () => {
  const { call } = setup();
  const text = new TextEncoder().encode('<script>');
  assert.equal(
    (await call('PUT', `object/${MINE}`, { body: text, type: 'text/html' })).status,
    415,
  );
  assert.equal(
    (await call('PUT', `object/${MINE}`, { body: text, type: 'image/jpeg' })).status,
    415,
  );
  const big = new Uint8Array(MAX_BYTES + 1);
  big.set(JPEG);
  assert.equal(
    (await call('PUT', `object/${MINE}`, { body: big, type: 'image/jpeg' })).status,
    413,
  );
});

test('rejects odd paths', async () => {
  const { call } = setup();
  for (const path of ['..%2Fx/y.jpg', `${ME}/../x.jpg`, 'single.jpg', `${ME}/a b.jpg`]) {
    const response = await call('PUT', `object/${path}`, {
      body: JPEG,
      type: 'image/jpeg',
    });
    assert.equal(response.status, 400, path);
  }
});

test('signs R2 photos with our link and older photos with Supabase', async () => {
  const { env, call } = setup();
  await env.PHOTOS.put(THEIRS, JPEG, { httpMetadata: { contentType: 'image/jpeg' } });
  const response = await call('POST', 'sign', {
    body: JSON.stringify({ paths: [THEIRS, OLD, `${OTHER}/farm/task/9_hidden.jpg`] }),
    type: 'application/json',
  });
  assert.equal(response.status, 200);
  const { urls } = await response.json();
  assert.deepEqual(Object.keys(urls).sort(), [OLD, THEIRS].sort());
  assert.match(urls[THEIRS], /^https:\/\/farm\.example\/api\/photos\/file\//);
  assert.equal(
    urls[OLD],
    `https://db.example/storage/v1/object/sign/farm-evidence/${OLD}?token=t`,
  );
});

test('a signed link serves the photo until it expires', async () => {
  const { env, call } = setup();
  await env.PHOTOS.put(MINE, JPEG, { httpMetadata: { contentType: 'image/jpeg' } });
  const signed = await call('POST', 'sign', {
    body: JSON.stringify({ paths: [MINE] }),
    type: 'application/json',
  });
  const link = new URL((await signed.json()).urls[MINE]);
  const route = link.pathname.replace('/api/photos/', '') + link.search;

  const ok = await call('GET', route, { token: null });
  assert.equal(ok.status, 200);
  assert.equal(ok.headers.get('Content-Type'), 'image/jpeg');
  assert.deepEqual(new Uint8Array(await ok.arrayBuffer()), JPEG);

  const later = await call('GET', route, { token: null, now: NOW + 3 * 3600 * 1000 });
  assert.equal(later.status, 403);

  const tampered = route.replace(MINE, MINE.replace('1_photo', '2_photo'));
  assert.equal((await call('GET', tampered, { token: null })).status, 403);
});

test('the same hour gives the same link (browser cache reuse)', async () => {
  const { env, call } = setup();
  await env.PHOTOS.put(MINE, JPEG, { httpMetadata: { contentType: 'image/jpeg' } });
  const sign = async (now) =>
    (await (await call('POST', 'sign', {
      body: JSON.stringify({ paths: [MINE] }),
      type: 'application/json',
      now,
    })).json()).urls[MINE];
  assert.equal(await sign(NOW), await sign(NOW + 20 * 60 * 1000));
});

test('a forged signature is refused', async () => {
  const { env, call } = setup();
  await env.PHOTOS.put(MINE, JPEG, { httpMetadata: { contentType: 'image/jpeg' } });
  const expires = Math.floor(NOW / 1000) + 3600;
  const forged = await hmac('wrong-secret', `${MINE}\n${expires}`);
  const response = await call('GET', `file/${MINE}?e=${expires}&s=${forged}`, { token: null });
  assert.equal(response.status, 403);
});

test('deletes your own R2 photo, or asks Supabase for an older one', async () => {
  const { env, call, calls } = setup();
  await env.PHOTOS.put(MINE, JPEG, { httpMetadata: { contentType: 'image/jpeg' } });
  assert.equal((await call('DELETE', `object/${MINE}`)).status, 200);
  assert.equal(env.PHOTOS.objects.size, 0);

  const older = `${ME}/farm/task/0_old.jpg`;
  assert.equal((await call('DELETE', `object/${older}`)).status, 200);
  assert.ok(calls.some((c) => c.url.endsWith('/storage/v1/object/farm-evidence')));

  assert.equal((await call('DELETE', `object/${THEIRS}`)).status, 403);
});

test('reports missing configuration instead of crashing', async () => {
  const { env, call } = setup();
  delete env.PHOTO_URL_SECRET;
  const response = await call('POST', 'sign', {
    body: JSON.stringify({ paths: [MINE] }),
    type: 'application/json',
  });
  assert.equal(response.status, 500);
  assert.deepEqual(await response.json(), { error: 'not_configured' });
});
