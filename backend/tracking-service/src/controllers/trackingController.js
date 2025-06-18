// src/controllers/trackingController.js
const TrackingService = require('../services/trackingService');

class TrackingController {
  
  // Atualizar localização do motorista
  static async updateLocation(req, res) {
  try {
    const { orderId, driverId, latitude, longitude, accuracy, speed, heading } = req.body;
    
    // Validação dos dados obrigatórios
    if (!orderId || !driverId || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        error: 'Dados obrigatórios ausentes',
        message: 'orderId, driverId, latitude e longitude são obrigatórios'
      });
    }
    
    // Validação de tipos e ranges
    const parsedOrderId = parseInt(orderId);
    const parsedDriverId = parseInt(driverId);
    const parsedLatitude = parseFloat(latitude);
    const parsedLongitude = parseFloat(longitude);
    
    // Verificar se os IDs são números válidos
    if (isNaN(parsedOrderId) || isNaN(parsedDriverId)) {
      return res.status(400).json({
        error: 'IDs inválidos',
        message: 'orderId e driverId devem ser números válidos'
      });
    }
    
    // Verificar se as coordenadas são válidas
    if (isNaN(parsedLatitude) || isNaN(parsedLongitude) || 
        parsedLatitude < -90 || parsedLatitude > 90 ||
        parsedLongitude < -180 || parsedLongitude > 180) {
      return res.status(400).json({
        error: 'Coordenadas inválidas',
        message: 'Latitude deve estar entre -90 e 90, longitude entre -180 e 180'
      });
    }
    
    // Verificar se os IDs estão dentro do range do BIGINT do PostgreSQL
    const MAX_BIGINT = 9223372036854775807;
    const MIN_BIGINT = -9223372036854775808;
    
    if (parsedOrderId > MAX_BIGINT || parsedOrderId < MIN_BIGINT ||
        parsedDriverId > MAX_BIGINT || parsedDriverId < MIN_BIGINT) {
      return res.status(400).json({
        error: 'IDs fora do range permitido',
        message: 'IDs devem estar dentro do range BIGINT do PostgreSQL'
      });
    }
    
    const locationData = {
      orderId: parsedOrderId,
      driverId: parsedDriverId,
      latitude: parsedLatitude,
      longitude: parsedLongitude,
      accuracy: accuracy ? parseFloat(accuracy) : null,
      speed: speed ? parseFloat(speed) : null,
      heading: heading ? parseFloat(heading) : null
    };
    
    console.log('Dados de localização validados:', locationData);
    
    const result = await TrackingService.updateLocation(locationData);
    
    res.status(201).json({
      success: true,
      message: 'Localização atualizada com sucesso',
      data: result
    });
    
  } catch (error) {
    console.error('Erro ao atualizar localização:', error);
    res.status(400).json({
      error: 'Erro ao atualizar localização',
      message: error.message
    });
  }
}
  
  // Obter localização atual de um pedido
  static async getCurrentLocation(req, res) {
    try {
      const { orderId } = req.params;
      
      if (!orderId || isNaN(orderId)) {
        return res.status(400).json({
          error: 'ID do pedido inválido',
          message: 'Forneça um ID de pedido válido'
        });
      }
      
      const result = await TrackingService.getCurrentLocation(parseInt(orderId));
      
      res.json({
        success: true,
        data: {
          currentLocation: result
        }
      });
      
    } catch (error) {
      console.error('Erro ao buscar localização atual:', error);
      
      if (error.message.includes('Nenhuma localização encontrada')) {
        return res.status(404).json({
          error: 'Localização não encontrada',
          message: error.message
        });
      }
      
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao buscar localização atual'
      });
    }
  }
  
  // Obter histórico de localização de um pedido
  static async getLocationHistory(req, res) {
    try {
      const { orderId } = req.params;
      const { limit = 50, offset = 0 } = req.query;
      
      if (!orderId || isNaN(orderId)) {
        return res.status(400).json({
          error: 'ID do pedido inválido',
          message: 'Forneça um ID de pedido válido'
        });
      }
      
      const result = await TrackingService.getLocationHistory(
        parseInt(orderId),
        parseInt(limit),
        parseInt(offset)
      );
      
      res.json({
        success: true,
        data: result
      });
      
    } catch (error) {
      console.error('Erro ao buscar histórico:', error);
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao buscar histórico de localização'
      });
    }
  }
  
  // Encontrar entregas próximas
  static async findNearbyDeliveries(req, res) {
    try {
      const { latitude, longitude, radius = 5 } = req.query;
      
      if (!latitude || !longitude) {
        return res.status(400).json({
          error: 'Coordenadas obrigatórias',
          message: 'latitude e longitude são obrigatórias'
        });
      }
      
      const result = await TrackingService.findNearbyDeliveries(
        parseFloat(latitude),
        parseFloat(longitude),
        parseFloat(radius)
      );
      
      res.json({
        success: true,
        data: result
      });
      
    } catch (error) {
      console.error('Erro ao buscar entregas próximas:', error);
      res.status(400).json({
        error: 'Erro ao buscar entregas próximas',
        message: error.message
      });
    }
  }
  
  // Obter estatísticas de rastreamento
  static async getStatistics(req, res) {
    try {
      const { startDate, endDate } = req.query;
      
      const result = await TrackingService.getTrackingStatistics(startDate, endDate);
      
      res.json({
        success: true,
        data: {
          statistics: result
        }
      });
      
    } catch (error) {
      console.error('Erro ao buscar estatísticas:', error);
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao buscar estatísticas'
      });
    }
  }
  
  // Verificar se pedido está sendo rastreado
  static async checkOrderTracking(req, res) {
    try {
      const { orderId } = req.params;
      
      if (!orderId || isNaN(orderId)) {
        return res.status(400).json({
          error: 'ID do pedido inválido',
          message: 'Forneça um ID de pedido válido'
        });
      }
      
      const isTracked = await TrackingService.isOrderBeingTracked(parseInt(orderId));
      
      res.json({
        success: true,
        data: {
          orderId: parseInt(orderId),
          isBeingTracked: isTracked
        }
      });
      
    } catch (error) {
      console.error('Erro ao verificar rastreamento:', error);
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao verificar rastreamento do pedido'
      });
    }
  }
  
  // Obter resumo de rastreamento por ID do motorista (sem autenticação)
  static async getDriverSummaryById(req, res) {
    try {
      const { driverId } = req.params;
      
      if (!driverId || isNaN(driverId)) {
        return res.status(400).json({
          error: 'ID do motorista inválido',
          message: 'Forneça um ID de motorista válido'
        });
      }
      
      const result = await TrackingService.getDriverTrackingSummary(parseInt(driverId));
      
      res.json({
        success: true,
        data: result
      });
      
    } catch (error) {
      console.error('Erro ao buscar resumo do motorista:', error);
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao buscar resumo de rastreamento'
      });
    }
  }
  
  // Obter resumo de rastreamento do motorista logado (para quando tem autenticação)
  static async getDriverSummary(req, res) {
    try {
      const driverId = req.user?.id;
      
      if (!driverId) {
        return res.status(400).json({
          error: 'ID do motorista não encontrado',
          message: 'Token de autenticação inválido'
        });
      }
      
      const result = await TrackingService.getDriverTrackingSummary(driverId);
      
      res.json({
        success: true,
        data: result
      });
      
    } catch (error) {
      console.error('Erro ao buscar resumo do motorista:', error);
      res.status(500).json({
        error: 'Erro interno',
        message: 'Erro ao buscar resumo de rastreamento'
      });
    }
  }
  
  // Health check específico do tracking
  static async healthCheck(req, res) {
    try {
      const stats = await TrackingService.getTrackingStatistics();
      
      res.json({
        status: 'OK',
        service: 'Tracking Service',
        timestamp: new Date().toISOString(),
        stats: {
          totalPoints: stats.totalPoints,
          trackedOrders: stats.trackedOrders,
          activeDrivers: stats.activeDrivers
        }
      });
      
    } catch (error) {
      console.error('Erro no health check:', error);
      res.status(503).json({
        status: 'ERROR',
        service: 'Tracking Service',
        timestamp: new Date().toISOString(),
        error: 'Serviço indisponível'
      });
    }
  }
}

module.exports = TrackingController;