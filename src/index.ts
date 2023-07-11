import express, { Request, Response } from 'express';
import cors from 'cors';
import { searchBook } from './opensearch';

// create and setup express index
const app = express();
app.use(express.json());
app.use(cors({ origin: true, credentials: true }));
app.get('/api/os/books', async (req: Request, res: Response) => {
  const { name } = req.query;
  const books = await searchBook(name as string);
  res.json({ message: `success`, data: books });
});

// start express server
app.listen(4000, () => {
  console.log('service start at 4000');
});
