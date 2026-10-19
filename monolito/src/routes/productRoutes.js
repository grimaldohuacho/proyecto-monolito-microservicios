const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/productos', productController.obtenerProductos);
router.post('/productos', productController.crearProducto);

module.exports = router;
