package com.example.gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;

@Configuration
public class RouteConfiguration {

    @Value("${AUTH_SERVICE_URL:http://auth-service:3000}")
    private String authServiceUrl;

    @Value("${ORDER_SERVICE_URL:http://order-service:8080}")
    private String orderServiceUrl;

    @Value("${TRACKING_SERVICE_URL:http://tracking-service:8081}")
    private String trackingServiceUrl;

    @Bean
    public RouteLocator routes(RouteLocatorBuilder builder) {
        return builder.routes()
                // Rota para auth-service
                .route("auth-service", r -> r
                        .path("/api/auth/**")
                        .filters(f -> f
                                .stripPrefix(1)
                                .circuitBreaker(config -> config
                                        .setName("authCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/auth"))
                                .retry(retryConfig -> {
                                    retryConfig.setRetries(3);
                                    retryConfig.setStatuses(HttpStatus.INTERNAL_SERVER_ERROR, HttpStatus.SERVICE_UNAVAILABLE);
                                }))
                        .uri(authServiceUrl))
                
                // Rota para order-service
                .route("order-service", r -> r
                        .path("/api/orders/**")
                        .filters(f -> f
                                .stripPrefix(1)
                                .circuitBreaker(config -> config
                                        .setName("orderCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/order"))
                                .retry(retryConfig -> {
                                    retryConfig.setRetries(3);
                                    retryConfig.setStatuses(HttpStatus.INTERNAL_SERVER_ERROR, HttpStatus.SERVICE_UNAVAILABLE);
                                }))
                        .uri(orderServiceUrl))
                
                // Rota para tracking-service
                .route("tracking-service", r -> r
                        .path("/api/tracking/**")
                        .filters(f -> f
                                .stripPrefix(1)
                                .circuitBreaker(config -> config
                                        .setName("trackingCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/tracking"))
                                .retry(retryConfig -> {
                                    retryConfig.setRetries(3);
                                    retryConfig.setStatuses(HttpStatus.INTERNAL_SERVER_ERROR, HttpStatus.SERVICE_UNAVAILABLE);
                                }))
                        .uri(trackingServiceUrl))
                
                // Rota de teste para circuit breaker
                .route("test-circuit-breaker", r -> r
                        .path("/api/test-cb/**")
                        .filters(f -> f
                                .stripPrefix(1)
                                .circuitBreaker(config -> config
                                        .setName("testCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/test"))
                                .retry(retryConfig -> {
                                    retryConfig.setRetries(3);
                                    retryConfig.setStatuses(HttpStatus.INTERNAL_SERVER_ERROR, HttpStatus.SERVICE_UNAVAILABLE);
                                }))
                        .uri("http://localhost:8000/test-circuit-breaker"))
                .build();
    }
}
