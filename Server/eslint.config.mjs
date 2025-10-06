import globals from "globals"
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { files: ["src/**/*.ts"] },
  { languageOptions: { globals: globals.node } },
  eslint.configs.recommended,
  tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    rules: {
      // "no-unused-vars": "off",
      "no-empty": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/no-misused-promises": "off",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/require-await": "warning",
      "@typescript-eslint/no-namespace": "off"
    }
  }
)
