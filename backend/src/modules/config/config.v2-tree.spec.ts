import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { ConfigService } from './config.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

describe('ConfigService - published survey tree', () => {
  let service: ConfigService;
  const store: any[] = [];

  const newest = (where: any) =>
    [...store]
      .filter((r) => r.treeType === where.treeType && (where.version === undefined || r.version === where.version))
      .sort((a, b) => b.version - a.version)[0] ?? null;

  const prisma = {
    v2TreeVersion: {
      findFirst: jest.fn(async ({ where }: any) => newest(where)),
      findMany: jest.fn(async ({ where }: any) =>
        store
          .filter((r) => r.treeType === where.treeType)
          .sort((a, b) => b.version - a.version)
          .map((r) => ({ ...r, publisher: { email: 'a@example.com' } })),
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

  const screen = (id: string, parentId: string | null = null, fields: any[] = []) => ({
    id, title: id, type: 'screen', parentId, order: 0, fields,
  });
  const tree = (nodes: any[] = [screen('s1'), screen('s2')]) => ({
    baseBundledVersion: 7,
    sections: [{ key: 'A', title: 'About', nodes }],
  });
  const upload = (t: any, baseVersion?: number, treeType = 'inspection_v2') =>
    service.uploadV2Tree({ treeType, tree: t, baseVersion } as any, 'u1');

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
  });

  describe('the trees shipped in the app', () => {
    const repo = path.resolve(__dirname, '..', '..', '..', '..');
    it.each([
      ['inspection_v2', 'assets/property_inspection/inspection_tree.json'],
      ['valuation_v2', 'assets/property_valuation/valuation_tree.json'],
    ])('%s can be published as it is', async (type, file) => {
      const asset = JSON.parse(fs.readFileSync(path.join(repo, file), 'utf8'));
      const result = await upload(asset, undefined, type);
      expect(result.version).toBe(1);
    });
  });

  describe('versions', () => {
    it('counts up and is audited', async () => {
      expect((await upload(tree())).version).toBe(1);
      expect((await upload(tree([screen('s1'), screen('s3')]))).version).toBe(2);
      expect(audit.log).toHaveBeenCalledTimes(2);
    });

    it('identical content makes no new version', async () => {
      await upload(tree());
      const again = await upload(tree());
      expect(again.unchanged).toBe(true);
      expect(again.version).toBe(1);
      expect(store).toHaveLength(1);
    });
  });

  describe('two people publishing', () => {
    it('the second, who started from the same version, is refused', async () => {
      await upload(tree());
      await upload(tree([screen('s1'), screen('web')]), 1);
      await expect(upload(tree([screen('s1'), screen('mobile')]), 1)).rejects.toBeInstanceOf(ConflictException);
      expect(store).toHaveLength(2);
    });

    it('starting from nothing published, when something is, is refused', async () => {
      await upload(tree());
      await expect(upload(tree([screen('s9')]), 0)).rejects.toBeInstanceOf(ConflictException);
    });

    it('the first publish from nothing works', async () => {
      expect((await upload(tree(), 0)).version).toBe(1);
    });

    it('losing the race at the database also says so', async () => {
      prisma.v2TreeVersion.create.mockRejectedValueOnce(
        Object.assign(Object.create(require('@prisma/client').Prisma.PrismaClientKnownRequestError.prototype), { code: 'P2002' }),
      );
      await expect(upload(tree())).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('a tree that would hurt', () => {
    it.each([
      ['no sections', { sections: [] }],
      ['a parent that does not exist', tree([screen('s1', 'ghost')])],
      ['a group with nothing in it', tree([{ id: 'g', title: 'G', type: 'group', parentId: null, order: 0 }])],
      ['a dropdown with no options', tree([screen('s1', null, [{ id: 'd', label: 'D', type: 'dropdown', options: [] }])])],
      ['a duplicate field', tree([screen('s1', null, [{ id: 'd', label: 'D', type: 'text' }, { id: 'd', label: 'D', type: 'text' }])])],
      ['a duplicate screen', tree([screen('s1'), screen('s1')])],
      ['an unknown field type', tree([screen('s1', null, [{ id: 'd', label: 'D', type: 'magic' }])])],
      ['a condition on a missing field', tree([screen('s1', null, [{ id: 'd', label: 'D', type: 'text', conditionalOn: 'ghost=Yes' }])])],
      ['a parent loop', tree([
        { id: 'g1', title: 'G1', type: 'group', parentId: 'g2', order: 0 },
        { id: 'g2', title: 'G2', type: 'group', parentId: 'g1', order: 0 },
      ])],
    ])('%s is refused', async (_name, bad) => {
      await expect(upload(bad)).rejects.toBeInstanceOf(BadRequestException);
      expect(store).toHaveLength(0);
    });

    it('a tree that lost over half its screens is refused', async () => {
      await upload(tree([screen('a'), screen('b'), screen('c'), screen('d')]));
      await expect(upload(tree([screen('a')]))).rejects.toThrow('Refusing to publish');
    });

    it('an unknown tree type is refused', async () => {
      await expect(upload(tree(), undefined, 'other')).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('what the phones read', () => {
    it('the tree, or nothing when they already have it', async () => {
      const { checksum } = await upload(tree());
      const first = await service.getPublishedTree('inspection_v2');
      expect(first.unchanged).toBe(false);
      expect(first.tree).toEqual(tree());
      const again = await service.getPublishedTree('inspection_v2', checksum);
      expect(again.unchanged).toBe(true);
      expect(again.tree).toBeUndefined();
    });

    it('nothing published is 404', async () => {
      await expect(service.getPublishedTree('inspection_v2')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('the version alone, 0 when none', async () => {
      expect(await service.getPublishedTreeVersion('inspection_v2')).toEqual({ version: 0 });
      await upload(tree());
      expect(await service.getPublishedTreeVersion('inspection_v2')).toEqual({ version: 1 });
    });

    it('trees and phrase banks stay apart', async () => {
      await upload(tree());
      await expect(service.getPublishedTree('valuation_v2')).rejects.toBeInstanceOf(NotFoundException);
      await expect(service.getPublishedTree('inspection_phrases')).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('history', () => {
    it('lists newest first with who published', async () => {
      await upload(tree());
      await upload(tree([screen('s1'), screen('s3')]));
      const list = await service.listTreeVersions('inspection_v2');
      expect(list.map((v) => v.version)).toEqual([2, 1]);
      expect(list[0].publishedBy).toBe('a@example.com');
      expect(list[0]).not.toHaveProperty('treeData');
    });

    it('rollback brings the old tree back as a new version, and the phones get it', async () => {
      const first = await upload(tree());
      await upload(tree([screen('s1'), screen('s3')]));
      const back = await service.rollbackTree('inspection_v2', { version: 1 } as any, 'u1');
      expect(back.version).toBe(3);
      expect(back.checksum).toBe(first.checksum);
      expect((await service.getPublishedTree('inspection_v2')).tree).toEqual(tree());
      expect(store).toHaveLength(3);
    });

    it('rollback of a version that never was is 404', async () => {
      await upload(tree());
      await expect(service.rollbackTree('inspection_v2', { version: 9 } as any, 'u1')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rollback also refuses to overwrite newer work', async () => {
      await upload(tree());
      await upload(tree([screen('s1'), screen('s3')]));
      await expect(
        service.rollbackTree('inspection_v2', { version: 1, baseVersion: 1 } as any, 'u1'),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });
});
