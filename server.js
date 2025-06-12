import express from 'express';
import path from 'path';
import compression from 'compression';
const app = express();
const PORT = process.env.PORT || 8080;

app.listen(PORT, () => console.log(`Server is running on http://localhost:${PORT}`));

app.use(compression());

app.use(express.static(path.resolve('./'), {
  setHeaders: (res, path, stat) => {
    const ext = path.split('.').pop().toLowerCase();
    switch (ext) {
      case 'terrain':
        res.setHeader('Content-Type', 'application/vnd.quantized-mesh');
        res.setHeader('Content-Encoding', 'gzip');
        break;
    }
  }
}));

app.get('/', (req, res) => res.sendFile(path.resolve('./index.html')));
