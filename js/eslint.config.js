import js from '@eslint/js';
import ts from 'typescript-eslint';
import { globalIgnores } from 'eslint/config';

import globals from 'globals';

export default ts.config(
  js.configs.recommended,
  ...ts.configs.recommended,
  globalIgnores(['bundle.js']),
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
  },
  {
    rules: {
      eqeqeq: 'error',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '_' }],
    },
  },
);
