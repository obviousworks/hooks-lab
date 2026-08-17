// Display helpers.

const LOCALE = "de-CH";

export function formatChf(amount) {
  return new Intl.NumberFormat(LOCALE, {
    style: "currency",
    currency: "CHF",
  }).format(amount);
}

export function formatLine(item) {
  return `${item.quantity} x ${item.name}: ${formatChf(item.price * item.quantity)}`;
}
