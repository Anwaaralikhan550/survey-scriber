/**
 * Simple CSV Writer Utility
 * Generates RFC 4180 compliant CSV output
 */

/**
 * Escapes a value for CSV output
 * - Wraps in quotes if contains comma, quote, or newline
 * - Doubles any existing quotes
 */
function escapeValue(value: any): string {
  if (value === null || value === undefined) {
    return '';
  }

  const stringValue = String(value);

  // Check if we need to quote the value
  if (
    stringValue.includes(',') ||
    stringValue.includes('"') ||
    stringValue.includes('\n') ||
    stringValue.includes('\r')
  ) {
    // Double any existing quotes and wrap in quotes
    return `"${stringValue.replace(/"/g, '""')}"`;
  }

  return stringValue;
}

/**
 * Generates CSV content from an array of objects
 *
 * @param data - Array of objects to convert to CSV
 * @param columns - Optional array of { key, header } to specify column order and headers
 * @returns CSV string with headers
 */
export function generateCsv<T extends Record<string, any>>(
  data: T[],
  columns?: { key: keyof T; header: string }[],
): string {
  if (data.length === 0) {
    return columns ? columns.map((c) => escapeValue(c.header)).join(',') : '';
  }

  // Determine columns from first row if not specified
  const effectiveColumns = columns || Object.keys(data[0]).map((key) => ({
    key: key as keyof T,
    header: key,
  }));

  // Generate header row
  const headerRow = effectiveColumns.map((c) => escapeValue(c.header)).join(',');

  // Generate data rows
  const dataRows = data.map((row) =>
    effectiveColumns.map((c) => escapeValue(row[c.key])).join(','),
  );

  return [headerRow, ...dataRows].join('\r\n');
}

/**
 * Formats a date to YYYY-MM-DD string
 */
export function formatDate(date: Date | null | undefined): string {
  if (!date) return '';
  return date.toISOString().split('T')[0];
}

/**
 * Formats a date to YYYY-MM-DD HH:mm:ss string
 */
export function formatDateTime(date: Date | null | undefined): string {
  if (!date) return '';
  return date.toISOString().replace('T', ' ').split('.')[0];
}

/**
 * Formats amount from pence to pounds with 2 decimal places
 */
export function formatCurrency(amountInPence: number | null | undefined): string {
  if (amountInPence === null || amountInPence === undefined) return '';
  return (amountInPence / 100).toFixed(2);
}
