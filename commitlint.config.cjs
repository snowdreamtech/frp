/**
 * Copyright (c) 2026 SnowdreamTech. All rights reserved.
 * Licensed under the MIT License. See LICENSE file in the project root for full license information.
 */

module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 120],
    "subject-max-length": [2, "always", 120],
    "body-max-line-length": [0, "always"],
    "footer-max-line-length": [0, "always"],
    // Custom rule: Disallow Chinese characters in commit messages
    "no-chinese": [2, "always"],
  },
  plugins: [
    {
      rules: {
        "no-chinese": ({ header, body, footer }) => {
          // Avoid matching "undefined" or "null" literal strings if parts are missing
          const text = [header, body, footer].filter(Boolean).join("\n");
          // Match CJK ideographs, CJK symbols/punctuation, and half/full-width forms
          const hasChinese = /[\u4e00-\u9fa5\u3000-\u303f\uff00-\uffef]/.test(text);
          return [
            !hasChinese,
            "Commit message must be in English only (no Chinese characters or punctuation allowed).",
          ];
        },
      },
    },
  ],
};
