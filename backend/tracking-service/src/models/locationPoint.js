// src/models/locationPoint.js
const { pool } = require('../config/database');

class LocationPoint {
  constructor(data) {
    this.id = data.id;
    this.orderId = data.order_id;
    this.driverId = data.driver_id;
    this.latitude = data.latitude;
    this.longitude = data.longitude;
    this.createdAt = data.created_at;
    this.accuracy = data.accuracy;
    this.speed = data.speed;
    this.heading = data.heading;
  }

  // Criar um novo ponto de localização
  static async create(locationData) {
    const { orderId, driverId, latitude, longitude, accuracy, speed, heading } = locationData;
    
    const query = `
      INSERT INTO location_points 
      (order_id, driver_id, latitude, longitude, accuracy, speed, heading) 
      VALUES ($1, $2, $3, $4, $5, $6, $7) 
      RETURNING *
    `;
    
    const values = [orderId, driverId, latitude, longitude, accuracy, speed, heading];
    const result = await pool.query(query, values);
    
    return new LocationPoint(result.rows[0]);
  }

  // Buscar localização atual de um pedido
  static async getCurrentByOrderId(orderId) {
    const query = `
      SELECT * FROM location_points 
      WHERE order_id = $1 
      ORDER BY created_at DESC 
      LIMIT 1
    `;
    
    const result = await pool.query(query, [orderId]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return new LocationPoint(result.rows[0]);
  }

  // Buscar histórico de localizações de um pedido
  static async getHistoryByOrderId(orderId, limit = 50, offset = 0) {
    const query = `
      SELECT * FROM location_points 
      WHERE order_id = $1 
      ORDER BY created_at DESC 
      LIMIT $2 OFFSET $3
    `;
    
    const result = await pool.query(query, [orderId, limit, offset]);
    
    return result.rows.map(row => new LocationPoint(row));
  }

  // Buscar todas as localizações mais recentes por pedido
  static async getLatestLocationsByDriver(driverId) {
    const query = `
      SELECT DISTINCT ON (order_id) 
        order_id, driver_id, latitude, longitude, created_at, accuracy, speed, heading
      FROM location_points 
      WHERE driver_id = $1
      ORDER BY order_id, created_at DESC
    `;
    
    const result = await pool.query(query, [driverId]);
    
    return result.rows.map(row => new LocationPoint(row));
  }

  // Buscar pontos de localização mais recentes de todos os pedidos
  static async getLatestLocations() {
    const query = `
      SELECT DISTINCT ON (order_id) 
        id, order_id, driver_id, latitude, longitude, created_at, accuracy, speed, heading
      FROM location_points 
      ORDER BY order_id, created_at DESC
    `;
    
    const result = await pool.query(query);
    
    return result.rows.map(row => new LocationPoint(row));
  }

  // Buscar estatísticas de rastreamento
  static async getStatistics(startDate = null, endDate = null) {
    let query = `
      SELECT 
        COUNT(*) as total_points,
        COUNT(DISTINCT order_id) as tracked_orders,
        COUNT(DISTINCT driver_id) as active_drivers,
        COALESCE(AVG(speed), 0) as avg_speed,
        MIN(created_at) as first_update,
        MAX(created_at) as last_update
      FROM location_points
    `;
    
    const params = [];
    
    if (startDate && endDate) {
      query += ` WHERE created_at BETWEEN $1 AND $2`;
      params.push(startDate, endDate);
    }
    
    const result = await pool.query(query, params);
    
    return result.rows[0];
  }

  // Contar total de pontos por pedido
  static async countPointsByOrderId(orderId) {
    const query = `
      SELECT COUNT(*) as total_points
      FROM location_points 
      WHERE order_id = $1
    `;
    
    const result = await pool.query(query, [orderId]);
    
    return parseInt(result.rows[0].total_points);
  }

  // Deletar pontos antigos (limpeza de dados)
  static async deleteOldPoints(daysOld = 90) {
    const query = `
      DELETE FROM location_points 
      WHERE created_at < NOW() - INTERVAL '${daysOld} days'
      RETURNING COUNT(*) as deleted_count
    `;
    
    const result = await pool.query(query);
    
    return result.rowCount;
  }

  // Método para converter para JSON
  toJSON() {
    return {
      id: this.id,
      orderId: this.orderId,
      driverId: this.driverId,
      latitude: parseFloat(this.latitude),
      longitude: parseFloat(this.longitude),
      createdAt: this.createdAt,
      accuracy: this.accuracy ? parseFloat(this.accuracy) : null,
      speed: this.speed ? parseFloat(this.speed) : null,
      heading: this.heading ? parseFloat(this.heading) : null
    };
  }
}

module.exports = LocationPoint;