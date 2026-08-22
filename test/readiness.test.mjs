import assert from 'node:assert/strict';
import test from 'node:test';

import { classify } from '../docs/readiness-logic.mjs';

const base = {
  team: '1-15',
  use: 'client',
  workflow: 'rooms',
  domain: 'yes',
  server: 'yes',
  recovery: 'yes',
  guests: 'yes',
};

test('ordinary small-team conversations fit the fixed pilot', () => {
  assert.equal(classify(base).tone, 'fit');
});

test('the published fifteen-account boundary fits the fixed pilot', () => {
  assert.equal(classify({ ...base, team: '1-15' }).tone, 'fit');
});

test('thread-dependent teams must validate the workflow first', () => {
  const result = classify({ ...base, workflow: 'threads' });
  assert.equal(result.tone, 'prepare');
  assert.ok(result.actions.some((action) => action.includes('Element threads')));
  assert.ok(result.actions.some((action) => action.includes('ticket state')));
});

test('ticket-style closure is explicitly outside the pilot', () => {
  const result = classify({ ...base, workflow: 'tickets' });
  assert.equal(result.tone, 'outside');
  assert.match(result.summary, /ticket states/);
});

test('calls and screen sharing are explicitly outside the pilot', () => {
  const result = classify({ ...base, workflow: 'calls' });
  assert.equal(result.tone, 'outside');
  assert.match(result.summary, /Calls, conferencing, and screen sharing/);
});

test('regulated and anonymity requirements remain outside the pilot', () => {
  assert.equal(classify({ ...base, use: 'regulated' }).tone, 'outside');
  assert.equal(classify({ ...base, use: 'anonymity' }).tone, 'outside');
});

test('larger initial groups and missing prerequisites require preparation', () => {
  const expanded = classify({ ...base, team: '16-50' });
  assert.equal(expanded.tone, 'prepare');
  assert.ok(expanded.actions.some((action) => action.includes('fifteen people')));
  assert.equal(classify({ ...base, domain: 'planned' }).tone, 'prepare');
  assert.equal(classify({ ...base, recovery: 'unsure' }).tone, 'prepare');
});
