/**
 * ESLint Base Configuration
 * Standard rules for all TypeScript/JavaScript projects
 * Extend with 'strict.js' or 'relaxed.js' as needed
 */
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'jsdoc'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:jsdoc/recommended-typescript',
    'prettier',
  ],
  rules: {
    // Documentation - required on public API
    'jsdoc/require-jsdoc': [
      'warn',
      {
        require: {
          FunctionDeclaration: true,
          MethodDefinition: true,
          ClassDeclaration: true,
        },
        publicOnly: true,
      },
    ],
    'jsdoc/require-description': 'warn',
    'jsdoc/require-param': 'warn',
    'jsdoc/require-returns': 'warn',

    // TypeScript
    '@typescript-eslint/explicit-function-return-type': 'warn',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',

    // Code quality
    'no-console': 'warn',
    complexity: ['warn', 15],
    'max-depth': ['warn', 4],
    'max-lines-per-function': ['warn', 100],
  },
  ignorePatterns: [
    'dist/',
    'build/',
    'node_modules/',
    'coverage/',
    '*.config.js',
    '*.config.ts',
  ],
};
