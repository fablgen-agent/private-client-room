import assert from 'node:assert/strict';
import test from 'node:test';

import { createStaticServer } from '../ops/serve.mjs';

async function withServer(run) {
  const server = createStaticServer();
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const address = server.address();
  try {
    await run(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

test('serves the homepage and guide without third-party execution allowances', async () => {
  await withServer(async (origin) => {
    const home = await fetch(`${origin}/`);
    assert.equal(home.status, 200);
    assert.match(home.headers.get('content-type'), /^text\/html/);
    assert.match(home.headers.get('content-security-policy'), /default-src 'self'/);
    assert.match(home.headers.get('content-security-policy'), /frame-ancestors 'none'/);
    assert.equal(home.headers.get('x-frame-options'), 'DENY');
    assert.equal(home.headers.get('x-content-type-options'), 'nosniff');
    assert.match(await home.text(), /Private Client Room/);

    const guide = await fetch(`${origin}/guides/private-slack-alternative/`);
    assert.equal(guide.status, 200);
    assert.match(await guide.text(), /private Slack alternative/i);
  });
});

test('supports HEAD and explicit directory redirects', async () => {
  await withServer(async (origin) => {
    const head = await fetch(`${origin}/styles.css`, { method: 'HEAD' });
    assert.equal(head.status, 200);
    assert.equal(await head.text(), '');
    assert.match(head.headers.get('content-type'), /^text\/css/);

    const redirect = await fetch(`${origin}/guides/private-slack-alternative?source=test`, { redirect: 'manual' });
    assert.equal(redirect.status, 308);
    assert.equal(redirect.headers.get('location'), '/guides/private-slack-alternative/?source=test');
  });
});

test('fails closed for unsupported methods, malformed paths, and missing files', async () => {
  await withServer(async (origin) => {
    const post = await fetch(`${origin}/`, { method: 'POST', body: 'ignored' });
    assert.equal(post.status, 405);
    assert.equal(post.headers.get('allow'), 'GET, HEAD');

    const traversal = await fetch(`${origin}/%2e%2e/README.md`);
    assert.ok([400, 404].includes(traversal.status));

    const missing = await fetch(`${origin}/not-present`);
    assert.equal(missing.status, 404);
    assert.equal(missing.headers.get('cache-control'), 'no-store');
  });
});
