import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import test from 'node:test';

const homepage = await readFile(new URL('../docs/index.html', import.meta.url), 'utf8');
const guide = await readFile(
  new URL('../docs/guides/private-slack-alternative/index.html', import.meta.url),
  'utf8',
);
const sitemap = await readFile(new URL('../docs/sitemap.xml', import.meta.url), 'utf8');
const robots = await readFile(new URL('../docs/robots.txt', import.meta.url), 'utf8');

const socialImage = new URL('../docs/assets/private-client-room-social.jpg', import.meta.url);
const heroImage = new URL('../docs/assets/private-client-room-hero.webp', import.meta.url);

test('publishes one branded canonical origin while retaining GitHub Pages as a mirror', () => {
  for (const page of [homepage, guide]) {
    assert.match(page, /https:\/\/room\.enby\.fish\//);
    assert.doesNotMatch(page, /fablgen-agent\.github\.io\/private-client-room/);
  }
  assert.doesNotMatch(sitemap, /fablgen-agent\.github\.io\/private-client-room/);
  assert.match(sitemap, /<loc>https:\/\/room\.enby\.fish\//);
  assert.match(robots, /Sitemap: https:\/\/room\.enby\.fish\/sitemap\.xml/);
});

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

test('private browser intake is primary while the local fit check and email remain', () => {
  const workLinks = homepage.match(/https:\/\/work\.enby\.fish\/\?service=private_room/g) || [];
  assert.equal(workLinks.length, 2);
  assert.match(homepage, /id="readiness-form"/);
  assert.match(homepage, /id="result-email" href="mailto:accounts@enby\.fish"/);
  assert.match(homepage, /Prefer email\?/);
  assert.match(guide, /https:\/\/work\.enby\.fish\/\?service=private_room/);
  assert.match(guide, /Email a non-sensitive enquiry/);
});

test('delivery copy exposes the read-only preflight without overstating it', () => {
  assert.match(homepage, /READ-ONLY PREFLIGHT/);
  assert.match(homepage, /delivery\/preflight\.sh/);
  assert.match(homepage, /does not log in remotely or change the server/);
});
