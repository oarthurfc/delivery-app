// src/utils/geoUtils.js

/**
 * Calcula a distância entre dois pontos usando a fórmula de Haversine
 * @param {number} lat1 Latitude do primeiro ponto
 * @param {number} lon1 Longitude do primeiro ponto
 * @param {number} lat2 Latitude do segundo ponto
 * @param {number} lon2 Longitude do segundo ponto
 * @returns {number} Distância em quilômetros
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Raio da Terra em quilômetros
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

/**
 * Converte graus para radianos
 * @param {number} degrees Valor em graus
 * @returns {number} Valor em radianos
 */
const toRadians = (degrees) => {
  return degrees * (Math.PI / 180);
};

/**
 * Valida se as coordenadas são válidas
 * @param {number} latitude 
 * @param {number} longitude 
 * @returns {boolean}
 */
const validateCoordinates = (latitude, longitude) => {
  const lat = parseFloat(latitude);
  const lon = parseFloat(longitude);
  
  return !isNaN(lat) && !isNaN(lon) && 
         lat >= -90 && lat <= 90 && 
         lon >= -180 && lon <= 180;
};

/**
 * Calcula a velocidade média entre dois pontos
 * @param {number} distance Distância em km
 * @param {number} timeInSeconds Tempo em segundos
 * @returns {number} Velocidade em km/h
 */
const calculateSpeed = (distance, timeInSeconds) => {
  if (timeInSeconds === 0) return 0;
  return (distance / timeInSeconds) * 3600; // Converter para km/h
};

/**
 * Calcula o centro geográfico de um conjunto de pontos
 * @param {Array} points Array de objetos com latitude e longitude
 * @returns {Object} Objeto com latitude e longitude do centro
 */
const calculateCenter = (points) => {
  if (!points || points.length === 0) {
    return null;
  }
  
  const sum = points.reduce((acc, point) => {
    acc.lat += parseFloat(point.latitude);
    acc.lon += parseFloat(point.longitude);
    return acc;
  }, { lat: 0, lon: 0 });
  
  return {
    latitude: sum.lat / points.length,
    longitude: sum.lon / points.length
  };
};

/**
 * Verifica se um ponto está dentro de um raio específico
 * @param {number} centerLat Latitude do centro
 * @param {number} centerLon Longitude do centro
 * @param {number} pointLat Latitude do ponto
 * @param {number} pointLon Longitude do ponto
 * @param {number} radiusKm Raio em quilômetros
 * @returns {boolean}
 */
const isWithinRadius = (centerLat, centerLon, pointLat, pointLon, radiusKm) => {
  const distance = calculateDistance(centerLat, centerLon, pointLat, pointLon);
  return distance <= radiusKm;
};

module.exports = {
  calculateDistance,
  toRadians,
  validateCoordinates,
  calculateSpeed,
  calculateCenter,
  isWithinRadius
};