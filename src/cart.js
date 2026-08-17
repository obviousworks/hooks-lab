// Shopping cart totals. Small on purpose: the point of this repository is the
// harness around the code, not the code itself.

const VAT_RATE = 0.081;

export function subtotal(items) {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

export function vat(amount) {
  return Math.round(amount * VAT_RATE * 100) / 100;
}

export function total(items) {
  const net = subtotal(items);
  return Math.round((net + vat(net)) * 100) / 100;
}

export function applyDiscount(amount, code) {
  if (code === "TEAM10") {
    return Math.round(amount * 0.9 * 100) / 100;
  }
  return amount;
}
