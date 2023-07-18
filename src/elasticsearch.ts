import { Client } from '@elastic/elasticsearch';

const esClient = new Client({ node: 'http://localhost:9201' });
const index = 'books';
export const searchBook = async (name: string) => {
  const query = { match: { name: { query: name } } };

  const response = await esClient.search({ index, query });

  return response.hits;
};
