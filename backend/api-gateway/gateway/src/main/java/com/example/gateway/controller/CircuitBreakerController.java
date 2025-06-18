package com.example.gateway.controller;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/actuator/circuit-breakers")
public class CircuitBreakerController {

    private final CircuitBreakerRegistry circuitBreakerRegistry;

    public CircuitBreakerController(CircuitBreakerRegistry circuitBreakerRegistry) {
        this.circuitBreakerRegistry = circuitBreakerRegistry;
    }

    @GetMapping
    public Mono<ResponseEntity<Map<String, Object>>> getCircuitBreakersStatus() {
        Map<String, Object> status = new HashMap<>();
        
        // Obter o status de todos os circuit breakers
        Map<String, String> circuitBreakers = circuitBreakerRegistry.getAllCircuitBreakers()
                .stream()
                .collect(Collectors.toMap(
                        CircuitBreaker::getName,
                        circuitBreaker -> circuitBreaker.getState().name()
                ));
        
        status.put("circuitBreakers", circuitBreakers);
        
        return Mono.just(ResponseEntity.ok(status));
    }
}
