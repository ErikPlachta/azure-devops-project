/**
 * ESLint Relaxed Configuration
 * Lighter rules for internal tools, scripts, POCs
 * Use sparingly - prefer base or strict
 */
const baseConfig = require('./base');

module.exports = {
  ...baseConfig,
  rules: {
    ...baseConfig.rules,

    // Documentation - warnings only
    'jsdoc/require-jsdoc': 'off',
    'jsdoc/require-description': 'off',
    'jsdoc/require-param': 'warn',
    'jsdoc/require-returns': 'warn',

    // TypeScript - relaxed
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',

    // Code quality - relaxed
    'no-console': 'off',
    complexity: ['warn', 20],
    'max-depth': ['warn', 5],
    'max-lines-per-function': 'off',
  },
};
