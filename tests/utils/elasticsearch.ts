import { Client } from '@elastic/elasticsearch';

const esClient = new Client({ node: 'http://localhost:9201' });
const index = 'books';

export const saveBook = async (bookDoc: { name: string; author: string }) => {
  await esClient.index({ index, body: bookDoc, refresh: true });
};
