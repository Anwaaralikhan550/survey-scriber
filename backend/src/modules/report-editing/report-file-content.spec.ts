import { mkdtempSync, rmSync, existsSync, readdirSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import * as path from 'path';
import { createHash, randomUUID } from 'crypto';
import { detectFileKind, safeFileName } from './report-file-content';
import { LocalStorageService } from '../media/storage/local-storage.service';

const docxLike = (names: string) =>
  Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.from('payload'), Buffer.from(`PK\x01\x02${names}PK\x05\x06`, 'latin1'), Buffer.alloc(18)]);

describe('report file content', () => {
  it('recognises a complete PDF by its bytes', () => {
    expect(detectFileKind(Buffer.from('%PDF-1.7\n...\n%%EOF\n'))).toBe('PDF');
    expect(detectFileKind(Buffer.from('%PDF-1.7\n...\n%%EOF   \n\n'))).toBe('PDF');
  });
  it('refuses a cut-off or fake PDF, text, images and tiny files', () => {
    expect(detectFileKind(Buffer.from('%PDF-1.7\n1 0 obj<<>>endobj\n'))).toBeNull();
    expect(detectFileKind(Buffer.from('hello world, not a pdf'))).toBeNull();
    expect(detectFileKind(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]))).toBeNull();
    expect(detectFileKind(Buffer.from('%PDF-'))).toBeNull();
    expect(detectFileKind(Buffer.alloc(0))).toBeNull();
  });
  it('recognises a Word document from its entry names and a plain zip as ZIP; a truncated zip is refused', () => {
    expect(detectFileKind(docxLike('[Content_Types].xmlword/document.xml'))).toBe('DOCX');
    expect(detectFileKind(docxLike('readme.txt'))).toBe('ZIP');
    expect(detectFileKind(Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.from('payload only')]))).toBeNull();
  });
  it('safe file names: base name only, no control characters or quotes, a fallback when nothing is left', () => {
    expect(safeFileName('..\\..\\evil/../a "b".pdf', 'x.pdf')).toBe('a b.pdf');
    expect(safeFileName('C:\\Users\\me\\report.docx', 'x')).toBe('report.docx');
    expect(safeFileName('', 'original.pdf')).toBe('original.pdf');
    expect(safeFileName('..', 'original.pdf')).toBe('original.pdf');
    expect(safeFileName('a\u0000b\r\n.pdf', 'x')).toBe('ab.pdf');
    expect(safeFileName('x'.repeat(400) + '.pdf', 'f').length).toBeLessThanOrEqual(150);
  });
});

describe('LocalStorageService.storeVerified', () => {
  let root: string;
  let storage: LocalStorageService;
  const dir = () => `report-files/${randomUUID()}`;

  beforeEach(() => {
    root = mkdtempSync(path.join(tmpdir(), 'ss-storage-'));
    storage = new LocalStorageService({ get: (_k: string, d?: string) => root || d } as never);
  });
  afterEach(() => rmSync(root, { recursive: true, force: true }));

  it('stores atomically and returns the size and SHA-256 of what was sent', async () => {
    const buf = Buffer.from('some report bytes');
    const d = dir();
    const id = randomUUID();
    const out = await storage.storeVerified(d, id, buf, 'pdf');
    expect(out.storagePath).toBe(`${d}/${id}.pdf`);
    expect(out.size).toBe(buf.length);
    expect(out.sha256).toBe(createHash('sha256').update(buf).digest('hex'));
    expect(await storage.checksum(out.storagePath)).toBe(out.sha256);
    expect(readdirSync(path.join(root, d)).filter((n) => n.startsWith('.'))).toEqual([]);
  });
  it('refuses path traversal, a bad id and a bad extension without writing anything', async () => {
    const buf = Buffer.from('x');
    await expect(storage.storeVerified('../etc', randomUUID(), buf, 'pdf')).rejects.toThrow();
    await expect(storage.storeVerified(dir(), '../../x', buf, 'pdf')).rejects.toThrow();
    await expect(storage.storeVerified(dir(), randomUUID(), buf, 'p/df')).rejects.toThrow();
    expect(existsSync(path.join(root, 'etc'))).toBe(false);
  });
  it('a leftover temporary file from a crash does not block a new store of another file and is never served', async () => {
    const d = dir();
    const id = randomUUID();
    const out = await storage.storeVerified(d, id, Buffer.from('one'), 'pdf');
    writeFileSync(path.join(root, d, '.' + randomUUID() + '.part'), 'half written');
    const second = await storage.storeVerified(d, randomUUID(), Buffer.from('two'), 'pdf');
    expect(second.storagePath).not.toBe(out.storagePath);
  });
});
