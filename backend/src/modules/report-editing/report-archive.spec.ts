import { zipSync, strToU8 } from 'fflate';
import { ARCHIVE_SCHEMA_VERSION, ArchiveError, ArchiveLimits, DEFAULT_LIMITS, Manifest, buildArchive, isAllowedPath, readArchive, sha256Hex, signManifest } from './report-archive';

const KEY = 'test-signing-key';
const ID = '11111111-2222-4333-8444-555555555555';
const MEDIA = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

const base = {
  producedBy: 'SurveyScriber',
  reportId: ID,
  surveyId: ID,
  ownerUserId: ID,
  exportedAt: '2026-11-19T10:00:00.000Z',
  exportedBy: ID,
  surveyType: 'INSPECTION',
  reportType: 'L2',
  status: 'DRAFT',
  originalVersion: 1,
  currentVersion: 1,
  finalVersion: null,
  treeVersionId: null,
  phraseBankVersionId: null,
  documents: [],
};

const entries = () => [
  { path: 'README.txt', data: Buffer.from('hello') },
  { path: 'final/report.json', data: Buffer.from('{"a":1}') },
  { path: `original/media/${MEDIA}.jpg`, data: Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]) },
];

/** A ZIP built by hand, to play the attacker. */
const raw = (files: Record<string, Uint8Array>) => Buffer.from(zipSync(files));

function manifestFor(files: Record<string, Uint8Array>, over: Partial<Manifest> = {}, key = KEY): Uint8Array {
  const unsigned = {
    archiveSchemaVersion: ARCHIVE_SCHEMA_VERSION,
    ...base,
    files: Object.entries(files).map(([path, data]) => ({ path, size: data.length, sha256: sha256Hex(Buffer.from(data)) })),
    ...over,
  };
  return strToU8(JSON.stringify({ ...unsigned, signature: signManifest(unsigned as Omit<Manifest, 'signature'>, key) }));
}

describe('archive paths', () => {
  it.each([
    'manifest.json',
    'README.txt',
    'original/snapshot.json',
    `original/media/${MEDIA}.jpg`,
    `original/media/${MEDIA}.png`,
    `final/documents/${MEDIA}.pdf`,
    `final/documents/${MEDIA}.docx`,
    'audit/events.json',
    'definitions/references.json',
  ])('%s is allowed', (p) => expect(isAllowedPath(p)).toBe(true));

  it.each([
    '../evil.txt',
    'original/../../evil.txt',
    '/etc/passwd',
    'original\\snapshot.json',
    'original/media/x.jpg',
    `original/media/${MEDIA}.exe`,
    `original/media/${MEDIA}.jpg/`,
    'final/extra.json',
    'script.sh',
    'original/snapshot.json\0.txt',
    `final/documents/${MEDIA}.zip`,
    'C:/evil.txt',
  ])('%s is refused', (p) => expect(isAllowedPath(p)).toBe(false));
});

describe('building and reading an archive', () => {
  it('round trip: every file comes back byte for byte, the manifest lists each with its SHA-256', () => {
    const { zip, manifest } = buildArchive(entries(), base, KEY);
    const read = readArchive(zip, KEY);
    expect([...read.files.keys()].sort()).toEqual(['README.txt', `original/media/${MEDIA}.jpg`, 'final/report.json', 'manifest.json'].sort());
    for (const e of entries()) expect(read.files.get(e.path)!.equals(e.data)).toBe(true);
    expect(read.manifest.files.map((f) => f.path).sort()).toEqual(entries().map((e) => e.path).sort());
    expect(read.manifest.files.find((f) => f.path === 'README.txt')!.sha256).toBe(sha256Hex(Buffer.from('hello')));
    expect(manifest.signature).toMatch(/^[0-9a-f]{64}$/);
    expect(read.manifest.reportId).toBe(ID);
  });

  it('refuses a path that is not on the list, and the same path twice, when building', () => {
    expect(() => buildArchive([{ path: '../x', data: Buffer.from('x') }], base, KEY)).toThrow();
    expect(() => buildArchive([...entries(), entries()[0]], base, KEY)).toThrow();
  });
});

describe('refusing a bad archive (spec 14.2)', () => {
  const reason = (zip: Buffer, limits?: ArchiveLimits, key = KEY): string => {
    try {
      readArchive(zip, key, limits);
    } catch (e) {
      expect(e).toBeInstanceOf(ArchiveError);
      return (e as Error).message;
    }
    throw new Error('the archive was accepted');
  };
  const good = { 'README.txt': strToU8('hello'), 'final/report.json': strToU8('{"a":1}') };
  const withManifest = (files: Record<string, Uint8Array>, over: Partial<Manifest> = {}, key = KEY) => raw({ ...files, 'manifest.json': manifestFor(files, over, key) });

  it('accepts a hand-made archive that is right (so the checks below are real)', () => {
    expect(() => readArchive(withManifest(good), KEY)).not.toThrow();
  });

  it('not a ZIP, empty, damaged', () => {
    expect(reason(Buffer.alloc(0))).toMatch(/empty/);
    expect(reason(Buffer.from('%PDF-1.4 definitely not a zip'))).toMatch(/not a ZIP/);
    const ok = withManifest(good);
    expect(reason(ok.subarray(0, ok.length - 30))).toMatch(/damaged|not a ZIP/);
    expect(reason(Buffer.concat([Buffer.from([0x50, 0x4b]), Buffer.alloc(80, 7)]))).toMatch(/damaged|not a ZIP/);
  });

  it('larger than allowed', () => {
    expect(reason(withManifest(good), { ...DEFAULT_LIMITS, maxArchiveBytes: 100 })).toMatch(/larger than allowed/);
  });

  it('path traversal, absolute and backslash paths, odd names, directories', () => {
    for (const evil of ['../evil.txt', 'original/../../evil.txt', '/etc/passwd', 'original\\x.json', 'final/other.json', 'run.sh']) {
      expect(reason(withManifest({ ...good, [evil]: strToU8('x') }))).toMatch(/Unexpected file or path/);
    }
    expect(reason(raw({ ...good, 'original/': new Uint8Array(0), 'manifest.json': manifestFor(good) }))).toMatch(/Unexpected file or path/);
  });

  it('a file that is in the archive but not in the manifest; one in the manifest but not in the archive', () => {
    const extra = raw({ ...good, 'audit/events.json': strToU8('[]'), 'manifest.json': manifestFor(good) });
    expect(reason(extra)).toMatch(/not in the manifest/);
    const gone = raw({ 'README.txt': good['README.txt'], 'manifest.json': manifestFor(good) });
    expect(reason(gone)).toMatch(/listed in the manifest but is not in the archive/);
  });

  it('a file changed after the archive was made', () => {
    const changed = raw({ ...good, 'final/report.json': strToU8('{"a":2}'), 'manifest.json': manifestFor(good) });
    expect(reason(changed)).toMatch(/checksum|size/);
    const sameSize = raw({ ...good, 'final/report.json': strToU8('{"a":9}'), 'manifest.json': manifestFor(good) });
    expect(reason(sameSize)).toMatch(/does not match its checksum/);
  });

  it('a manifest rewritten with matching checksums but not signed by this server', () => {
    const files = { ...good, 'final/report.json': strToU8('{"a":9}') };
    expect(reason(withManifest(files, {}, 'attacker-key'))).toMatch(/signature does not match/);
    const unsigned = JSON.parse(Buffer.from(manifestFor(files)).toString());
    delete unsigned.signature;
    expect(reason(raw({ ...files, 'manifest.json': strToU8(JSON.stringify(unsigned)) }))).toMatch(/signature/);
  });

  it('a manifest field changed after signing', () => {
    const m = JSON.parse(Buffer.from(manifestFor(good)).toString());
    m.ownerUserId = '99999999-2222-4333-8444-555555555555';
    expect(reason(raw({ ...good, 'manifest.json': strToU8(JSON.stringify(m)) }))).toMatch(/signature/);
  });

  it('unsupported archive schema; manifest missing or not JSON', () => {
    expect(reason(withManifest(good, { archiveSchemaVersion: 99 }))).toMatch(/schema version 99 is not supported/);
    expect(reason(raw(good))).toMatch(/manifest.json is missing/);
    expect(reason(raw({ ...good, 'manifest.json': strToU8('not json') }))).toMatch(/not valid JSON/);
    expect(reason(raw({ ...good, 'manifest.json': strToU8('[]') }))).toMatch(/not valid/);
  });

  it('ZIP bomb: one file that unpacks to far more than allowed, a high expansion ratio, too many files, too much in total', () => {
    const big = new Uint8Array(3 * 1024 * 1024); // 3 MB of zeros: tiny when compressed
    const files = { ...good, 'audit/events.json': big };
    expect(reason(withManifest(files), { ...DEFAULT_LIMITS, maxEntryBytes: 1024 * 1024 })).toMatch(/larger than allowed/);
    expect(reason(withManifest(files), { ...DEFAULT_LIMITS, maxRatio: 20 })).toMatch(/expands suspiciously/);
    expect(reason(withManifest(files), { ...DEFAULT_LIMITS, maxTotalBytes: 2 * 1024 * 1024, maxRatio: 1e9 })).toMatch(/unpacks to more than allowed/);
    expect(reason(withManifest(good), { ...DEFAULT_LIMITS, maxEntries: 2 })).toMatch(/too many files/);
  });

  it('a size that lies: declared smaller than the real data', () => {
    const ok = Buffer.from(withManifest(good));
    // the first local header holds its sizes at offset 22 (uncompressed) - make the central directory entry lie instead
    const eocd = ok.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
    const cdStart = ok.readUInt32LE(eocd + 16);
    expect(ok.readUInt32LE(cdStart)).toBe(0x02014b50);
    ok.writeUInt32LE(2, cdStart + 24); // original size claims 2 bytes
    expect(() => readArchive(ok, KEY)).toThrow(ArchiveError);
  });

  it('a duplicate name in the table of contents', () => {
    const files = { 'audit/events.json': strToU8('b'), 'final/report.json': strToU8('c') };
    const zip = Buffer.from(raw({ ...files, 'manifest.json': manifestFor(files) }));
    // both names have 17 characters: rename the second to the first in its local header and in the central directory
    let from = 0;
    for (;;) {
      const at = zip.indexOf('final/report.json', from);
      if (at < 0) break;
      zip.write('audit/events.json', at, 'latin1');
      from = at + 1;
    }
    expect(reason(zip)).toMatch(/twice|damaged/);
  });
});
