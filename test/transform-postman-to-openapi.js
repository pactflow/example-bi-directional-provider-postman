const collection = './test/PactflowProductsAPI.postman_collection.json';
const postmanToOpenApi = require('postman-to-openapi')
const filePath = __dirname + "/../oas/swagger.yml"

async function main() {
    try {
        const result = await postmanToOpenApi(collection, filePath, { defaultTag: 'General' })

    } catch (err) {
        console.log(err)
    }
}

main()