import { createHash, createHmac, timingSafeEqual } from 'crypto';
import { unzipSync, zipSync, Zippable } from 'fflate';

/**
 * The complete archive of a report (Remote Editor spec v1.4 section 14): one ZIP with a manifest that lists every file with its
 * SHA-256, the original and final documents and data, the pictures and signatures themselves, the audit history and a README.
 * This file is the pure part: building the ZIP and reading one back with every check of section 14.2 (structure, paths, sizes,
 * ZIP bombs, unexpected files, checksums, signature). It touches no database and no disk.
 */
export const ARCHIVE_SCHEMA_VERSION = 1;
export const SUPPORTED_ARCHIVE_SCHEMAS = [1];

export class ArchiveError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ArchiveError';
  }
}

export interface ArchiveLimits {
  /** the uploaded ZIP */
  maxArchiveBytes: number;
  /** every file inside, when unpacked */
  maxEntryBytes: number;
  /** all files inside together, when unpacked */
  maxTotalBytes: number;
  maxEntries: number;
  /** compressed -> unpacked growth allowed for a file larger than 1 MB */
  maxRatio: number;
}

export const DEFAULT_LIMITS: ArchiveLimits = {
  maxArchiveBytes: 256 * 1024 * 1024,
  maxEntryBytes: 64 * 1024 * 1024,
  maxTotalBytes: 768 * 1024 * 1024,
  maxEntries: 3000,
  maxRatio: 200,
};

const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
/** The only paths an archive may contain. Everything else is refused. */
const ALLOWED_PATHS: RegExp[] = [
  /^manifest\.json$/,
  /^README\.txt$/,
  /^original\/snapshot\.json$/,
  new RegExp(`^original/documents/${UUID}\\.(pdf|docx)$`),
  new RegExp(`^original/media/${UUID}\\.(jpg|png)$`),
  /^final\/report\.json$/,
  /^final\/survey\.json$/,
  /^final\/media\.json$/,
  new RegExp(`^final/documents/${UUID}\\.(pdf|docx)$`),
  new RegExp(`^final/media/${UUID}\\.(jpg|png)$`),
  /^audit\/events\.json$/,
  /^audit\/versions\.json$/,
  /^audit\/reviews\.json$/,
  /^definitions\/references\.json$/,
];

export function isAllowedPath(path: string): boolean {
  if (path.length > 200 || path.includes('..') || path.includes('\\') || path.startsWith('/') || path.includes('\0')) return false;
  return ALLOWED_PATHS.some((re) => re.test(path));
}

export function sha256Hex(data: Uint8Array | Buffer): string {
  return createHash('sha256').update(data).digest('hex');
}

export interface ManifestFile {
  path: string;
  size: number;
  sha256: string;
}

export interface ArchiveDocument {
  path: string;
  state: 'ORIGINAL' | 'FINAL';
  kind: 'PDF' | 'DOCX';
  fileName: string;
  cycle: number;
  version: number | null;
}

export interface Manifest {
  archiveSchemaVersion: number;
  producedBy: string;
  reportId: string;
  surveyId: string;
  ownerUserId: string;
  exportedAt: string;
  exportedBy: string;
  surveyType: string;
  reportType: string;
  status: string;
  originalVersion: number;
  currentVersion: number;
  finalVersion: number | null;
  treeVersionId: string | null;
  phraseBankVersionId: string | null;
  documents: ArchiveDocument[];
  files: ManifestFile[];
  signature?: string;
}

export interface ArchiveEntry {
  path: string;
  data: Buffer;
}

/** The signature proves the manifest was made by a SurveyScriber server holding the key (so a rewritten manifest and checksums are refused). */
export function signManifest(manifest: Omit<Manifest, 'signature'>, key: string): string {
  return createHmac('sha256', key).update(JSON.stringify(manifest)).digest('hex');
}

function signatureMatches(manifest: Manifest, key: string): boolean {
  const { signature, ...rest } = manifest;
  if (typeof signature !== 'string' || !/^[0-9a-f]{64}$/.test(signature)) return false;
  const expected = Buffer.from(signManifest(rest, key), 'hex');
  const given = Buffer.from(signature, 'hex');
  return expected.length === given.length && timingSafeEqual(expected, given);
}

const BINARY = /\.(pdf|docx|jpg|png)$/;

/** Builds the ZIP: the files, a manifest listing each with its SHA-256, signed. Pictures and documents are stored as they are (already compressed). */
export function buildArchive(entries: ArchiveEntry[], base: Omit<Manifest, 'files' | 'signature' | 'archiveSchemaVersion'>, key: string): { zip: Buffer; manifest: Manifest } {
  const seen = new Set<string>();
  for (const e of entries) {
    if (!isAllowedPath(e.path)) throw new Error(`archive path not allowed: ${e.path}`);
    if (seen.has(e.path)) throw new Error(`archive path twice: ${e.path}`);
    seen.add(e.path);
  }
  const unsigned: Omit<Manifest, 'signature'> = {
    archiveSchemaVersion: ARCHIVE_SCHEMA_VERSION,
    ...base,
    files: entries.filter((e) => e.path !== 'manifest.json').map((e) => ({ path: e.path, size: e.data.length, sha256: sha256Hex(e.data) })),
  };
  const manifest: Manifest = { ...unsigned, signature: signManifest(unsigned, key) };
  const zippable: Zippable = {};
  for (const e of entries) zippable[e.path] = [new Uint8Array(e.data), { level: BINARY.test(e.path) ? 0 : 6 }];
  zippable['manifest.json'] = [new Uint8Array(Buffer.from(JSON.stringify(manifest, null, 2), 'utf8')), { level: 6 }];
  return { zip: Buffer.from(zipSync(zippable)), manifest };
}

export interface ReadArchive {
  manifest: Manifest;
  files: Map<string, Buffer>;
}

/** Everything section 14.2 asks to be checked before anything is restored. Throws [ArchiveError] with the reason. */
export function readArchive(zip: Buffer, key: string, limits: ArchiveLimits = DEFAULT_LIMITS): ReadArchive {
  if (zip.length === 0) throw new ArchiveError('The file is empty');
  if (zip.length > limits.maxArchiveBytes) throw new ArchiveError('The archive is larger than allowed');
  if (zip.length < 4 || zip[0] !== 0x50 || zip[1] !== 0x4b) throw new ArchiveError('This is not a SurveyScriber archive (not a ZIP file)');

  // 1. Read the table of contents only: names and sizes as declared. Nothing is unpacked yet.
  const declared: { name: string; size: number; originalSize: number; compression: number }[] = [];
  try {
    unzipSync(new Uint8Array(zip), {
      filter: (f) => {
        declared.push({ name: f.name, size: f.size, originalSize: f.originalSize, compression: f.compression });
        return false;
      },
    });
  } catch {
    throw new ArchiveError('The ZIP file is damaged or not a ZIP file');
  }
  if (declared.length === 0) throw new ArchiveError('The archive is empty');
  if (declared.length > limits.maxEntries) throw new ArchiveError('The archive has too many files');

  const names = new Set<string>();
  let total = 0;
  for (const f of declared) {
    if (!isAllowedPath(f.name)) throw new ArchiveError(`Unexpected file or path in the archive: ${printable(f.name)}`);
    if (names.has(f.name)) throw new ArchiveError(`The archive lists ${f.name} twice`);
    names.add(f.name);
    if (f.compression !== 0 && f.compression !== 8) throw new ArchiveError(`Unsupported compression in ${f.name}`);
    if (f.originalSize > limits.maxEntryBytes) throw new ArchiveError(`${f.name} is larger than allowed`);
    if (f.originalSize > 1024 * 1024 && f.size > 0 && f.originalSize / f.size > limits.maxRatio) throw new ArchiveError(`${f.name} expands suspiciously (possible ZIP bomb)`);
    total += f.originalSize;
    if (total > limits.maxTotalBytes) throw new ArchiveError('The archive unpacks to more than allowed');
  }
  if (!names.has('manifest.json')) throw new ArchiveError('manifest.json is missing');

  // 2. Unpack. The declared size bounds the output; the real size must be the declared one.
  let unpacked: Record<string, Uint8Array>;
  try {
    unpacked = unzipSync(new Uint8Array(zip));
  } catch {
    throw new ArchiveError('The ZIP file is damaged');
  }
  const files = new Map<string, Buffer>();
  for (const f of declared) {
    const data = unpacked[f.name];
    if (!data || data.length !== f.originalSize) throw new ArchiveError(`${f.name} does not match its declared size`);
    files.set(f.name, Buffer.from(data));
  }

  // 3. The manifest: schema, signature, and every file against its checksum.
  let manifest: Manifest;
  try {
    manifest = JSON.parse(files.get('manifest.json')!.toString('utf8')) as Manifest;
  } catch {
    throw new ArchiveError('manifest.json is not valid JSON');
  }
  if (!manifest || typeof manifest !== 'object' || Array.isArray(manifest)) throw new ArchiveError('manifest.json is not valid');
  if (!SUPPORTED_ARCHIVE_SCHEMAS.includes(manifest.archiveSchemaVersion)) {
    throw new ArchiveError(`Archive schema version ${printable(String(manifest.archiveSchemaVersion))} is not supported (supported: ${SUPPORTED_ARCHIVE_SCHEMAS.join(', ')})`);
  }
  if (!signatureMatches(manifest, key)) throw new ArchiveError('The archive was changed after it was made, or was not made by this SurveyScriber (signature does not match)');
  if (!Array.isArray(manifest.files)) throw new ArchiveError('manifest.json has no file list');
  const listed = new Set<string>();
  for (const m of manifest.files) {
    if (!m || typeof m.path !== 'string' || typeof m.sha256 !== 'string' || typeof m.size !== 'number') throw new ArchiveError('manifest.json has a bad file entry');
    if (listed.has(m.path)) throw new ArchiveError(`manifest.json lists ${m.path} twice`);
    listed.add(m.path);
    const data = files.get(m.path);
    if (!data) throw new ArchiveError(`${m.path} is listed in the manifest but is not in the archive`);
    if (data.length !== m.size) throw new ArchiveError(`${m.path} has a different size than the manifest says`);
    if (sha256Hex(data) !== m.sha256) throw new ArchiveError(`${m.path} does not match its checksum (changed or damaged)`);
  }
  for (const name of names) if (name !== 'manifest.json' && !listed.has(name)) throw new ArchiveError(`${name} is in the archive but not in the manifest`);
  return { manifest, files };
}

function printable(s: string): string {
  // eslint-disable-next-line no-control-regex
  return s.replace(/[\u0000-\u001f\u007f]/g, '?').slice(0, 80);
}

export function readmeText(m: { reportId: string; exportedAt: string; exportedBy: string; status: string; originalVersion: number; currentVersion: number; finalVersion: number | null }): string {
  return [
    'SurveyScriber - complete report archive',
    '=======================================',
    '',
    `Report (survey) id : ${m.reportId}`,
    `Made on            : ${m.exportedAt}`,
    `Made by (user id)  : ${m.exportedBy}`,
    `Status when made   : ${m.status}`,
    `Versions           : original v${m.originalVersion}, latest v${m.currentVersion}${m.finalVersion === null ? '' : `, final v${m.finalVersion}`}`,
    '',
    'What is inside',
    '--------------',
    'manifest.json            the list of every file with its SHA-256 checksum, and a signature. Do not edit it.',
    'original/                the report exactly as the phone first produced it: structured data, the PDF and Word files,',
    '                         the original photographs and signatures (also the ones later replaced or deleted).',
    'final/                   the latest (or final) structured report, survey data, the final PDF and Word files, and the',
    '                         pictures added in the browser.',
    'audit/                   who changed what, when: field-level history, every saved version, reviews and finalisation.',
    'definitions/             which question tree and phrase bank the report was written with.',
    '',
    'The PDF and Word files are kept as they were made. They do not change if SurveyScriber is updated later.',
    '',
    'How to restore it',
    '-----------------',
    'In the SurveyScriber app open the report list, choose "Restore archived report" and pick this ZIP file.',
    'Only a complete, unchanged archive made by SurveyScriber can be restored, and only by its owner.',
    'A report that still exists in SurveyScriber is never overwritten: the restore is refused.',
    'The restored report is marked "Restored from archive"; its earlier history is shown as imported history.',
    '',
    'Keep this file in your own secure storage. Reports are deleted from the SurveyScriber cloud after the retention period;',
    'downloading an archive does not extend it.',
    '',
  ].join('\n');
}
