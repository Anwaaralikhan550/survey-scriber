/**
 * What a report document really is, decided from its bytes and never from the file name or the label the client sent
 * (Remote Editor spec v1.4 sections 9, 16 and 18). Pure functions, no I/O.
 */
export type DetectedKind = 'PDF' | 'DOCX' | 'ZIP';

const PK = Buffer.from([0x50, 0x4b, 0x03, 0x04]);

export function detectFileKind(buffer: Buffer): DetectedKind | null {
  if (buffer.length < 8) return null;
  if (buffer.subarray(0, 5).toString('latin1') === '%PDF-') {
    // A real PDF ends with %%EOF (trailing whitespace allowed). A cut-off upload does not.
    const tail = buffer.subarray(Math.max(0, buffer.length - 2048)).toString('latin1');
    return tail.includes('%%EOF') ? 'PDF' : null;
  }
  if (buffer.subarray(0, 4).equals(PK)) {
    // The names of the entries are listed in the central directory at the end of the file.
    const tail = buffer.subarray(Math.max(0, buffer.length - 262144)).toString('latin1');
    if (!tail.includes('PK\x05\x06') && !tail.includes('PK\x01\x02')) return null; // no end record: truncated
    return tail.includes('[Content_Types].xml') && tail.includes('word/document.xml') ? 'DOCX' : 'ZIP';
  }
  return null;
}

/** A plain, safe name for the Content-Disposition header: base name only, no path, no control characters. */
export function safeFileName(raw: string | undefined, fallback: string): string {
  const base = (raw ?? '').split(/[\\/]/).pop() ?? '';
  // eslint-disable-next-line no-control-regex
  const clean = base.replace(/[\u0000-\u001F\u007F"<>:*?|]/g, '').replace(/\s+/g, ' ').trim().slice(0, 150);
  return clean.length > 0 && clean !== '.' && clean !== '..' ? clean : fallback;
}

export const EXTENSION: Record<DetectedKind, string> = { PDF: 'pdf', DOCX: 'docx', ZIP: 'zip' };
export const MIME: Record<DetectedKind, string> = {
  PDF: 'application/pdf',
  DOCX: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ZIP: 'application/zip',
};
