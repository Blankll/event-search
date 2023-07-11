import { saveBook } from './utils/elasticsearch';
import { searchBook } from '../src/elasticsearch';
const mockBook = {
  name: 'jest elasticsearch',
  author: 'jest',
};

describe('integration test for elasticsearch', () => {
  beforeAll(async () => {
    await saveBook(mockBook);
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
