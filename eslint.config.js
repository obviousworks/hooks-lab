// Lint rules for the hooks lab.
//
// Deliberately few, and loud on failure. Task E needs a check that fails
// predictably on a violation an agent will produce when asked, and that names
// the broken rule clearly enough for a model to act on it.
export default [
  {
    files: ["src/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
    },
    rules: {
      "no-unused-vars": "error",
      "no-var": "error",
      "prefer-const": "error",
      "eqeqeq": ["error", "always"],
      "no-console": "error",
    },
  },
];
