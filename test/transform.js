const collection = require('./PactflowProductsAPI.postman_collection.json');
const { transpile } = require('postman2openapi');
const fs = require('fs')

const postman = JSON.stringify(collection);
const openapi = transpile(postman, 'yaml');
const filePath = __dirname + "/../oas/oas_from_postman_collection.yml"

fs.writeFileSync(filePath, openapi);

console.log('Postman collection successfully converted to OAS and stored at the following location',filePath)