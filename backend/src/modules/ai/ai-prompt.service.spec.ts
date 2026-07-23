import { AiPromptService } from './ai-prompt.service';

describe('AiPromptService report prompt', () => {
  const service = new AiPromptService({} as never);

  it('uses a concise report contract and cache-busting version', () => {
    const prompt = service.getPrompt('REPORT');

    expect(prompt.version).toBe('v1.2.0');
    expect(prompt.systemPrompt).toContain('Maximum 180 words');
    expect(prompt.userPromptTemplate).toContain('no more than 180 words');
    expect(prompt.systemPrompt).not.toContain('at least 100 lines');
    expect(prompt.userPromptTemplate).not.toContain('100+ lines');
    expect(prompt.systemPrompt).not.toContain('RICS-compliant');
  });
});
