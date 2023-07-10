import express, {Request, Response} from "express";
import cors from "cors";


// create and setup express index
const index = express();
index.use(express.json());
index.use(cors({origin: true, credentials: true}))


index.get('/api/cookie/tst', (eq: Request, res: Response) => {
  res.json({message: `success ${eq.method}`});
})
index.post('/api/cookie/tst', (eq: Request, res: Response) => {
  res.json({message: `success ${eq.method}`});
})

// start express server
index.listen(4000, () => {
  console.log('service start at 4000')
});
