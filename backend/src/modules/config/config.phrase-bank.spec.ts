import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';
import { ConfigService } from './config.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

describe('ConfigService - phrase bank publishing (live phrase edits)', () => {
  let service: ConfigService;

  const store: any[] = [];
  const prisma = {
    v2TreeVersion: {
      findFirst: jest.fn(async ({ where }: any) =>
        [...store].filter((r) => r.treeType === where.treeType).sort((a, b) => b.version - a.version)[0] ?? null,
      ),
      create: jest.fn(async ({ data }: any) => {
        const rec = { id: `id-${store.length + 1}`, publishedAt: new Date(), createdAt: new Date(), ...data };
        store.push(rec);
        return rec;
      }),
    },
    configVersion: { findFirst: jest.fn(), updateMany: jest.fn(), create: jest.fn(), update: jest.fn() },
  };
  const audit = { log: jest.fn() };

  const inspectionBank = (n = 10) =>
    Object.fromEntries(Array.from({ length: n }, (_, i) => [`{M}::{S${i}}`, `Sentence ${i} {TOKEN_${i}}.`]));
  const valuationBank = (n = 4) => ({
    meta: { schemaVersion: 1 },
    templates: Object.fromEntries(Array.from({ length: n }, (_, i) => [`VAL_${i}`, { screenId: '*', text: `Text ${i}.` }])),
  });

  beforeEach(async () => {
    store.length = 0;
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConfigService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = module.get(ConfigService);
    // config version bump is exercised elsewhere; keep this unit focused
    jest.spyOn(service as any, 'incrementConfigVersion').mockResolvedValue(undefined);
  });

  it('publishes an inspection bank as version 1 and returns its checksum', async () => {
    const bank = inspectionBank();
    const r = await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank }, 'admin-1');
    expect(r.version).toBe(1);
    expect(r.unchanged).toBe(false);
    expect(r.checksum).toBe(crypto.createHash('sha256').update(JSON.stringify(bank)).digest('hex'));
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({ action: 'config.phrase_bank_published' }));
  });

  it('a changed bank becomes the next version and phones get it', async () => {
    await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank() }, 'a');
    const edited = { ...inspectionBank(), '{M}::{S0}': 'New wording {TOKEN_0}.' };
    const r = await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: edited }, 'a');
    expect(r.version).toBe(2);
    const latest = await service.getLatestPhraseBank('inspection_phrases');
    expect(latest.version).toBe(2);
    expect((latest.bank as any)['{M}::{S0}']).toBe('New wording {TOKEN_0}.');
  });

  it('identical content is not published twice (idempotent)', async () => {
    await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank() }, 'a');
    const again = await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank() }, 'a');
    expect(again.unchanged).toBe(true);
    expect(again.version).toBe(1);
    expect(store).toHaveLength(1);
  });

  it('latest omits the body when the phone already has that checksum', async () => {
    const up = await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank() }, 'a');
    const same = await service.getLatestPhraseBank('inspection_phrases', up.checksum);
    expect(same.unchanged).toBe(true);
    expect(same.bank).toBeUndefined();
    const other = await service.getLatestPhraseBank('inspection_phrases', 'something-else');
    expect(other.unchanged).toBe(false);
    expect(other.bank).toBeDefined();
  });

  it('valuation bank keeps its {meta, templates} shape', async () => {
    await service.uploadPhraseBank({ bankType: 'valuation_phrases', bank: valuationBank() }, 'a');
    const latest = await service.getLatestPhraseBank('valuation_phrases');
    expect((latest.bank as any).templates.VAL_0.text).toBe('Text 0.');
    expect((latest.bank as any).meta.schemaVersion).toBe(1);
  });

  it('rejects broken banks', async () => {
    await expect(
      service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: { k: 5 as any } }, 'a'),
    ).rejects.toThrow(BadRequestException);
    await expect(service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: {} }, 'a')).rejects.toThrow(
      'empty',
    );
    await expect(
      service.uploadPhraseBank({ bankType: 'valuation_phrases', bank: { meta: {} } }, 'a'),
    ).rejects.toThrow('templates');
    await expect(
      service.uploadPhraseBank({ bankType: 'valuation_phrases', bank: { templates: { X: { text: '' } } } }, 'a'),
    ).rejects.toThrow('non-empty');
  });

  it('refuses a bank that lost more than half of the phrases (wrong/truncated file)', async () => {
    await service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank(10) }, 'a');
    await expect(
      service.uploadPhraseBank({ bankType: 'inspection_phrases', bank: inspectionBank(4) }, 'a'),
    ).rejects.toThrow('Refusing to publish');
    expect(store).toHaveLength(1);
  });

  it('latest: 404 when nothing is published, 400 for an unknown type', async () => {
    await expect(service.getLatestPhraseBank('inspection_phrases')).rejects.toThrow(NotFoundException);
    await expect(service.getLatestPhraseBank('nope')).rejects.toThrow(BadRequestException);
  });
});
