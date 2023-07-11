import { Client } from '@elastic/elasticsearch';

const esClient = new Client({ node: 'http://localhost:9201' });
const index = 'books';
export const searchBook = async (name: string) => {
  const query = { query: { match: { name: { query: name } } } };

  const { body } = await esClient.search({ index, body: query });

  return body.hits;
};
