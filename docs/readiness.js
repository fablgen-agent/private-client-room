import { classify, labels } from './readiness-logic.mjs';

const form = document.querySelector('#readiness-form');
const result = document.querySelector('#readiness-result');
const resultLabel = document.querySelector('#result-label');
const resultTitle = document.querySelector('#result-title');
const resultSummary = document.querySelector('#result-summary');
const resultActions = document.querySelector('#result-actions');
const resultEmail = document.querySelector('#result-email');

function setActions(items) {
  resultActions.replaceChildren();
  for (const item of items) {
    const row = document.createElement('li');
    row.textContent = item;
    resultActions.append(row);
  }
}

form.addEventListener('submit', (event) => {
  event.preventDefault();
  if (!form.reportValidity()) return;

  const values = Object.fromEntries(new FormData(form));
  const outcome = classify(values);
  result.dataset.tone = outcome.tone;
  resultLabel.textContent = outcome.label;
  resultTitle.textContent = outcome.title;
  resultSummary.textContent = outcome.summary;
  setActions(outcome.actions);

  const body = [
    `Readiness result: ${outcome.label}`,
    '',
    `Team size: ${labels.team[values.team]}`,
    `Main use: ${labels.use[values.use]}`,
    `Conversation structure: ${labels.workflow[values.workflow]}`,
    `Domain: ${labels.domain[values.domain]}`,
    `Server: ${labels.server[values.server]}`,
    `Recovery: ${labels.recovery[values.recovery]}`,
    `Guests: ${labels.guests[values.guests]}`,
    '',
    'Please confirm whether this fits the £199 pilot. I have not included credentials or private data.',
  ].join('\n');
  resultEmail.href = `mailto:accounts@enby.fish?subject=${encodeURIComponent('Private Client Room fit check')}&body=${encodeURIComponent(body)}`;

  result.hidden = false;
  result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  resultTitle.focus({ preventScroll: true });
});

form.addEventListener('reset', () => {
  result.hidden = true;
  result.removeAttribute('data-tone');
});

resultTitle.tabIndex = -1;
