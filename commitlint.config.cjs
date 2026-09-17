// ADR-036 : Conventional Commits. Les scopes correspondent aux modules du SRS V2.0 chap. 5.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'm1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm7',
      'backend', 'frontend', 'shared', 'db', 'infra', 'ci', 'docs', 'deps', 'security', 'i18n', 'a11y', 'release',
    ]],
    'subject-case': [0],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [0],
  },
};
