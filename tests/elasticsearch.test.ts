import { saveBook } from './utils/elasticsearch';
import { searchBook } from '../src/elasticsearch';
import { startEngine, stopEngine } from '@geek-fun/jest-search';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import loadConfig from '../jest-search-config.js';

const mockBook = {
  name: 'jest elasticsearch',
  author: 'jest',
};

describe('integration test for elasticsearch', () => {
  beforeAll(async () => {
    await startEngine(loadConfig());
    await saveBook(mockBook);
  });
  afterAll(async () => {
    await stopEngine();
  });
  it('should get book when search with valid book name', async () => {
    const bookHits = await searchBook('jest elasticsearch');

    expect(bookHits).toMatchObject({
      total: { value: 1, relation: 'eq' },
      hits: [
        {
          _index: 'books',
          _source: {
            name: 'jest elasticsearch',
            author: 'jest',
          },
        },
      ],
    });
  });
});
