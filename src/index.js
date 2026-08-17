// Entry point. Kept import-only so `npm run lint` is clean on a fresh clone.

import { total, applyDiscount } from "./cart.js";
import { formatChf, formatLine } from "./format.js";

export function receipt(items, discountCode) {
  const lines = items.map(formatLine);
  const gross = applyDiscount(total(items), discountCode);
  return {
    lines,
    total: formatChf(gross),
  };
}
