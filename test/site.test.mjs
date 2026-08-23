import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import test from 'node:test';

const homepage = await readFile(new URL('../docs/index.html', import.meta.url), 'utf8');
const guide = await readFile(
  new URL('../docs/guides/private-slack-alternative/index.html', import.meta.url),
  'utf8',
);

const socialImage = new URL('../docs/assets/private-client-room-social.jpg', import.meta.url);
const heroImage = new URL('../docs/assets/private-client-room-hero.webp', import.meta.url);

test('home and guide publish complete large-image social metadata', () => {
  for (const page of [homepage, guide]) {
    assert.match(page, /<meta name="twitter:card" content="summary_large_image">/);
    assert.match(page, /<meta property="og:image:width" content="1200">/);
    assert.match(page, /<meta property="og:image:height" content="630">/);
    assert.match(page, /private-client-room-social\.jpg/);
    assert.match(page, /<meta property="og:image:alt" content="[^"]+">/);
  }
});

test('rendered visuals have useful alternative text and an honest caption', () => {
  for (const page of [homepage, guide]) {
    assert.match(page, /<img[^>]+private-client-room-hero\.webp[^>]+alt="[^"]+"/);
    assert.match(page, /<figcaption>[^<]*(?:boundary|metadata)[^<]*<\/figcaption>/i);
  }
});

test('optimized image assets are present and bounded', async () => {
  const [socialBytes, heroBytes, socialStats, heroStats] = await Promise.all([
    readFile(socialImage),
    readFile(heroImage),
    stat(socialImage),
    stat(heroImage),
  ]);

  assert.deepEqual([...socialBytes.subarray(0, 3)], [0xff, 0xd8, 0xff]);
  assert.equal(heroBytes.subarray(0, 4).toString('ascii'), 'RIFF');
  assert.equal(heroBytes.subarray(8, 12).toString('ascii'), 'WEBP');
  assert.ok(socialStats.size < 150_000);
  assert.ok(heroStats.size < 150_000);
});
