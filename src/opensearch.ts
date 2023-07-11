import { Client } from '@opensearch-project/opensearch';
const index = 'books';
const osClient = new Client({ node: 'http://localhost:9202' });

export const searchBook = async (name: string) => {
  console.log('search-name', name);
  const query = {
    query: {
      match: {
        name: { query: name },
      },
    },
  };

  const { body } = await osClient.search({
    index,
    body: query,
  });

  return body.hits;
};
