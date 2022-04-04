const express = require('express');
const app = express();
const cors = require('cors');
const routes = require('./src/product/product.routes');

const port = 3001;

const init = () => {
    app.use(express.json());
    app.use(cors());
    app.use(routes);
    return app.listen(port, () => console.log(`Provider API listening on port ${port}...`));
};

init();
