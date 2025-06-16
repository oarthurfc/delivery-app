// src/services/trackingService.js
const LocationPoint = require('../models/locationPoint');
const { calculateDistance, validateCoordinates, isWithinRadius } = require('../utils/geoUtils');

class TrackingService {
  
  // Atualizar localização do motorista
  static async updateLocation(locationData) {
    const { orderId, driverId, latitude, longitude, accuracy, speed, heading } = locationData;
    
    // Validar coordenadas
    if (!validateCoordinates(latitude, longitude)) {
      throw new Error('Coordenadas GPS inválidas');
    }
    
    // Criar novo ponto de localização
    const locationPoint = await LocationPoint.create({
      orderId,
      driverId,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      accuracy: accuracy ? parseFloat(accuracy) : null,
      speed: speed ? parseFloat(speed) : null,
      heading: heading ? parseFloat(heading) : null
    });
    
    return locationPoint.toJSON();
  }
  
  // Obter localização atual de um pedido
  static async getCurrentLocation(orderId) {
    const locationPoint = await LocationPoint.getCurrentByOrderId(orderId);
    
    if (!locationPoint) {
      throw new Error('Nenhuma localização encontrada para este pedido');
    }
    
    return locationPoint.toJSON();
  }
  
  // Obter histórico de localização com cálculos de distância
  static async getLocationHistory(orderId, limit = 50, offset = 0) {
    const locationHistory = await LocationPoint.getHistoryByOrderId(orderId, limit, offset);
    
    if (locationHistory.length === 0) {
      return {
        locationHistory: [],
        totalDistance: 0,
        totalPoints: 0,
        averageSpeed: 0
      };
    }
    
    // Calcular distância total percorrida
    let totalDistance = 0;
    let totalSpeed = 0;
    let speedCount = 0;
    
    for (let i = 1; i < locationHistory.length; i++) {
      const prev = locationHistory[i];
      const curr = locationHistory[i - 1];
      
      const distance = calculateDistance(
        parseFloat(prev.latitude),
        parseFloat(prev.longitude),
        parseFloat(curr.latitude),
        parseFloat(curr.longitude)
      );
      
      totalDistance += distance;
      
      // Calcular velocidade média se disponível
      if (curr.speed && curr.speed > 0) {
        totalSpeed += parseFloat(curr.speed);
        speedCount++;
      }
    }
    
    const averageSpeed = speedCount > 0 ? totalSpeed / speedCount : 0;
    
    return {
      locationHistory: locationHistory.map(point => point.toJSON()),
      totalDistance: parseFloat(totalDistance.toFixed(2)),
      totalPoints: locationHistory.length,
      averageSpeed: parseFloat(averageSpeed.toFixed(2))
    };
  }
  
  // Encontrar entregas próximas a uma localização
  static async findNearbyDeliveries(latitude, longitude, radiusKm = 5) {
    // Validar coordenadas
    if (!validateCoordinates(latitude, longitude)) {
      throw new Error('Coordenadas GPS inválidas');
    }
    
    // Buscar todas as localizações mais recentes
    const latestLocations = await LocationPoint.getLatestLocations();
    
    // Filtrar pontos dentro do raio especificado
    const nearbyDeliveries = latestLocations
      .filter(point => isWithinRadius(
        parseFloat(latitude),
        parseFloat(longitude),
        parseFloat(point.latitude),
        parseFloat(point.longitude),
        parseFloat(radiusKm)
      ))
      .map(point => {
        const distance = calculateDistance(
          parseFloat(latitude),
          parseFloat(longitude),
          parseFloat(point.latitude),
          parseFloat(point.longitude)
        );
        
        return {
          ...point.toJSON(),
          distance: parseFloat(distance.toFixed(2))
        };
      })
      .sort((a, b) => a.distance - b.distance); // Ordenar por distância
    
    return {
      nearbyDeliveries,
      searchCenter: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude)
      },
      searchRadius: parseFloat(radiusKm),
      totalFound: nearbyDeliveries.length
    };
  }
  
  // Obter estatísticas de rastreamento
  static async getTrackingStatistics(startDate = null, endDate = null) {
    const stats = await LocationPoint.getStatistics(startDate, endDate);
    
    return {
      totalPoints: parseInt(stats.total_points),
      trackedOrders: parseInt(stats.tracked_orders),
      activeDrivers: parseInt(stats.active_drivers),
      averageSpeed: parseFloat(parseFloat(stats.avg_speed).toFixed(2)),
      firstUpdate: stats.first_update,
      lastUpdate: stats.last_update,
      period: {
        startDate: startDate || stats.first_update,
        endDate: endDate || stats.last_update
      }
    };
  }
  
  // Verificar se um pedido está sendo rastreado
  static async isOrderBeingTracked(orderId) {
    try {
      const locationPoint = await LocationPoint.getCurrentByOrderId(orderId);
      return locationPoint !== null;
    } catch (error) {
      return false;
    }
  }
  
  // Obter resumo de rastreamento para um motorista
  static async getDriverTrackingSummary(driverId) {
    const driverLocations = await LocationPoint.getLatestLocationsByDriver(driverId);
    
    const activeOrders = driverLocations.length;
    
    return {
      driverId: parseInt(driverId),
      activeOrders,
      locations: driverLocations.map(point => point.toJSON())
    };
  }
  
  // Limpar dados antigos (manutenção)
  static async cleanupOldData(daysOld = 90) {
    const deletedCount = await LocationPoint.deleteOldPoints(daysOld);
    
    return {
      deletedPoints: deletedCount,
      retentionDays: daysOld,
      cleanupDate: new Date().toISOString()
    };
  }
}

module.exports = TrackingService;