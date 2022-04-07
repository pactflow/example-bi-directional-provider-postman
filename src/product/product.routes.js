const router = require('express').Router();
const controller = require('./product.controller');

router.get("/products/:id", controller.getById);
router.get("/products", controller.getAll);
router.post("/products", controller.create);

module.exports = router;