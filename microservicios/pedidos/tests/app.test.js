const request = require('supertest');
const app = require('../src/app');
const pool = require('../src/db');

afterAll(async () => {
    await pool.end();
});

test('GET /health debe responder correctamente', async () => {
    const response = await request(app).get('/health');

    expect(response.statusCode).toBe(200);
    expect(response.body.service).toBe('Pedidos');
});

test('GET /pedidos debe devolver una lista', async () => {
    const response = await request(app).get('/pedidos');

    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
});
