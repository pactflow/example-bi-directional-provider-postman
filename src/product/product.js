class Product {
  constructor({ id, name, type, price, version }) {
    if (!id || !name || !type || !price || !version) {
      throw new Error("invalid product object");
    }
    this.id = id;
    this.name = name;
    this.type = type;
    this.price = price;
    this.version = version;
  }
}

module.exports = Product;
