const Product = require("./product");

class ProductRepository {
  constructor() {
    this.products = new Map([
      [
        "09",
        new Product({
          id: "09",
          type: "CREDIT_CARD",
          name: "Gem Visa",
          version: "v1",
          price: 99.99,
        }),
      ],
      [
        "10",
        new Product({
          id: "10",
          type: "CREDIT_CARD",
          name: "28 Degrees",
          version: "v1",
          price: 49.49,
        }),
      ],
      [
        "11",
        new Product({
          id: "11",
          type: "PERSONAL_LOAN",
          name: "MyFlexiPay",
          version: "v2",
          price: 16.5,
        }),
      ],
    ]);
  }

  async fetchAll() {
    return [...this.products.values()];
  }

  async getById(id) {
    return this.products.get(id);
  }

  async create(product) {
    return this.products.set(product.id, product);
  }
}

module.exports = ProductRepository;
