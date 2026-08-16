const form = document.querySelector('#readiness-form');
const result = document.querySelector('#readiness-result');
const resultLabel = document.querySelector('#result-label');
const resultTitle = document.querySelector('#result-title');
const resultSummary = document.querySelector('#result-summary');
const resultActions = document.querySelector('#result-actions');
const resultEmail = document.querySelector('#result-email');

const labels = {
  team: {
    '1-10': '1–10 people',
    '11-50': '11–50 people',
    '51-plus': 'More than 50 people',
  },
  use: {
    client: 'Everyday client or team conversations',
    community: 'A private community',
    regulated: 'Regulated or legally privileged data',
    anonymity: 'Guaranteed anonymity or whistleblowing',
  },
  domain: {
    yes: 'Domain and DNS already controlled',
    planned: 'Domain and DNS can be arranged',
    no: 'No domain control currently',
  },
  server: {
    yes: 'Ubuntu server already controlled',
    planned: 'Ubuntu server can be arranged',
    no: 'No server control currently',
  },
  recovery: {
    yes: 'Recovery-key owner can be appointed',
    unsure: 'Recovery ownership needs guidance',
    no: 'No recovery-key owner available',
  },
  guests: {
    yes: 'Invited clients or guests needed',
    no: 'Internal team only',
    unsure: 'Guest pattern not decided',
  },
};

function setActions(items) {
  resultActions.replaceChildren();
  for (const item of items) {
    const row = document.createElement('li');
    row.textContent = item;
    resultActions.append(row);
  }
}

function classify(values) {
  if (values.use === 'regulated' || values.use === 'anonymity') {
    return {
      tone: 'outside',
      label: 'OUTSIDE THE PILOT',
      title: 'This fixed scope is not the right boundary.',
      summary: 'The pilot does not cover regulated-data approval, legally privileged workflows, or guaranteed anonymity.',
      actions: [
        'Do not place sensitive material into a trial deployment.',
        'Use a qualified legal, compliance, or specialist anonymity review before choosing a platform.',
      ],
    };
  }

  if (values.team === '51-plus') {
    return {
      tone: 'outside',
      label: 'OUTSIDE THE PILOT',
      title: 'The initial deployment is too large for this offer.',
      summary: 'The £199 pilot is limited to ten initial accounts and three rooms.',
      actions: [
        'Define a smaller pilot group before requesting a fit check.',
        'Treat a wider rollout as separately scoped work, not as part of this price.',
      ],
    };
  }

  const missingInfrastructure = values.domain !== 'yes' || values.server !== 'yes';
  const recoveryNeedsWork = values.recovery !== 'yes';
  const expandedTeam = values.team === '11-50';

  if (missingInfrastructure || recoveryNeedsWork || expandedTeam) {
    const actions = [];
    if (values.domain !== 'yes') actions.push('Arrange a customer-owned domain with editable DNS.');
    if (values.server !== 'yes') actions.push('Arrange a customer-owned Ubuntu server; hosting is paid directly by you.');
    if (recoveryNeedsWork) actions.push('Appoint a person responsible for recovery material before handover.');
    if (expandedTeam) actions.push('Choose up to ten people for the initial pilot.');
    return {
      tone: 'prepare',
      label: 'PREPARATION NEEDED',
      title: 'The use case may fit after a few prerequisites.',
      summary: 'Nothing here requires sharing credentials or private conversations during the fit check.',
      actions,
    };
  }

  return {
    tone: 'fit',
    label: 'PILOT FIT',
    title: 'This looks compatible with the fixed pilot.',
    summary: 'The final decision still depends on a written scope check; this result is not a security or compliance assessment.',
    actions: [
      'Confirm the intended domain, server ownership, and initial room pattern without sending credentials.',
      'Agree the five acceptance checks before deployment begins.',
      'Pay only after those agreed checks pass.',
    ],
  };
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
