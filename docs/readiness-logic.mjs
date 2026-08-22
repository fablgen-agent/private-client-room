export const labels = {
  team: {
    '1-15': '1–15 people',
    '16-50': '16–50 people',
    '51-plus': 'More than 50 people',
  },
  use: {
    client: 'Everyday client or team conversations',
    community: 'A private community',
    regulated: 'Regulated or legally privileged data',
    anonymity: 'Guaranteed anonymity or whistleblowing',
  },
  workflow: {
    rooms: 'Ordinary rooms, messages, and files',
    threads: 'Threaded discussions are important',
    tickets: 'Topics must have ticket-style closure',
    calls: 'Calls or screen sharing are essential',
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

export function classify(values) {
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

  if (values.workflow === 'tickets' || values.workflow === 'calls') {
    const ticketWorkflow = values.workflow === 'tickets';
    return {
      tone: 'outside',
      label: 'OUTSIDE THE PILOT',
      title: 'The required workflow is not part of this offer.',
      summary: ticketWorkflow
        ? 'The pilot validates private rooms, messages, files, and access. It does not add ticket states or a resolved-topic workflow.'
        : 'Calls, conferencing, and screen sharing are not included in the pilot acceptance checks.',
      actions: ticketWorkflow
        ? [
            'Evaluate a topic-first system such as Zulip or a dedicated issue tracker before choosing Matrix.',
            'Do not buy this pilot if ticket-style closure is a mandatory acceptance requirement.',
          ]
        : [
            'Choose a service with calls in its tested deployment and support scope.',
            'Do not assume text-message acceptance checks prove call quality or reliability.',
          ],
    };
  }

  if (values.team === '51-plus') {
    return {
      tone: 'outside',
      label: 'OUTSIDE THE PILOT',
      title: 'The initial deployment is too large for this offer.',
      summary: 'The £199 pilot is limited to fifteen initial accounts and three rooms.',
      actions: [
        'Define a smaller pilot group before requesting a fit check.',
        'Treat a wider rollout as separately scoped work, not as part of this price.',
      ],
    };
  }

  const missingInfrastructure = values.domain !== 'yes' || values.server !== 'yes';
  const recoveryNeedsWork = values.recovery !== 'yes';
  const expandedTeam = values.team === '16-50';
  const threadsNeedValidation = values.workflow === 'threads';

  if (missingInfrastructure || recoveryNeedsWork || expandedTeam || threadsNeedValidation) {
    const actions = [];
    if (values.domain !== 'yes') actions.push('Arrange a customer-owned domain with editable DNS.');
    if (values.server !== 'yes') actions.push('Arrange a customer-owned Ubuntu server; hosting is paid directly by you.');
    if (recoveryNeedsWork) actions.push('Appoint a person responsible for recovery material before handover.');
    if (expandedTeam) actions.push('Choose up to fifteen people for the initial pilot.');
    if (threadsNeedValidation) {
      actions.push('Test Element threads on every required client before agreeing scope.');
      actions.push('Confirm that no ticket state or resolved-topic workflow is required.');
    }
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
