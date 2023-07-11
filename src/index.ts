import express, { Request, Response } from 'express';
import cors from 'cors';
import { searchBook } from './opensearch';
import { searchBook as searchBookInES } from './elasticsearch';
// create and setup express index
const app = express();
app.use(express.json());
app.use(cors({ origin: true, credentials: true }));
app.get('/api/os/books', async (req: Request, res: Response) => {
  const { name } = req.query;

  console.log('opensearch-event', { name });
  const books = await searchBook(name as string);
  res.json({ message: `success`, data: books });
});

app.get('/api/es/books', async (req: Request, res: Response) => {
  const { name } = req.query;

  console.log('elasticsearch-event', { name });
  const books = await searchBookInES(name as string);
  res.json({ message: `success`, data: books });
});

// start express server
app.listen(4000, () => {
  console.log('service start at 4000');
});
