const collection = require('./PactflowProductsAPI.postman_collection.json');
const { transpile } = require('postman2openapi');
const fs = require('fs')

const postman = JSON.stringify(collection);
const openapi = transpile(postman, 'yaml');

fs.writeFileSync(__dirname + "/../oas/swagger_converted.yml", openapi);