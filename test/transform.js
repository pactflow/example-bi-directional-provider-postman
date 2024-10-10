const collection = require('./PactflowProductsAPI.postman_collection');
const { transpile } = require('postman2openapi');
const fs = require('fs')

const openapi = transpile(collection);
const filePath = __dirname + "/../oas/swagger.json"

fs.writeFileSync(filePath, JSON.stringify(openapi, null, 2));
