package com.example.gateway.controller;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/test-circuit-breaker")
public class CircuitBreakerTestController {

    private final CircuitBreakerRegistry circuitBreakerRegistry;
    private final WebClient.Builder webClientBuilder;

    public CircuitBreakerTestController(CircuitBreakerRegistry circuitBreakerRegistry, 
                                       WebClient.Builder webClientBuilder) {
        this.circuitBreakerRegistry = circuitBreakerRegistry;
        this.webClientBuilder = webClientBuilder;
    }

    @GetMapping("/slow-response/{seconds}")
    public Mono<ResponseEntity<Map<String, Object>>> simulateSlowResponse(@PathVariable int seconds) {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Resposta após " + seconds + " segundos");
        
        // Simula uma resposta lenta
        return Mono.just(response)
                .delayElement(Duration.ofSeconds(seconds))
                .map(r -> ResponseEntity.ok(r));
    }

    @GetMapping("/force-error")
    public Mono<ResponseEntity<Map<String, Object>>> simulateError() {
        return Mono.error(new RuntimeException("Erro forçado para testar circuit breaker"));
    }

    @GetMapping("/status/{circuitName}")
    public Mono<ResponseEntity<Map<String, Object>>> getCircuitStatus(@PathVariable String circuitName) {
        Map<String, Object> status = new HashMap<>();
        
        try {
            CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker(circuitName);
            status.put("name", circuitBreaker.getName());
            status.put("state", circuitBreaker.getState());
            status.put("metrics", Map.of(
                "failureRate", circuitBreaker.getMetrics().getFailureRate(),
                "slowCallRate", circuitBreaker.getMetrics().getSlowCallRate(),
                "numberOfSuccessfulCalls", circuitBreaker.getMetrics().getNumberOfSuccessfulCalls(),
                "numberOfFailedCalls", circuitBreaker.getMetrics().getNumberOfFailedCalls(),
                "numberOfSlowCalls", circuitBreaker.getMetrics().getNumberOfSlowCalls()
            ));
            
            return Mono.just(ResponseEntity.ok(status));
        } catch (Exception e) {
            status.put("error", "Circuit breaker não encontrado: " + circuitName);
            return Mono.just(ResponseEntity.badRequest().body(status));
        }
    }

    @GetMapping("/reset/{circuitName}")
    public Mono<ResponseEntity<Map<String, Object>>> resetCircuit(@PathVariable String circuitName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker(circuitName);
            circuitBreaker.reset();
            result.put("message", "Circuit breaker resetado com sucesso: " + circuitName);
            result.put("currentState", circuitBreaker.getState());
            
            return Mono.just(ResponseEntity.ok(result));
        } catch (Exception e) {
            result.put("error", "Falha ao resetar circuit breaker: " + e.getMessage());
            return Mono.just(ResponseEntity.badRequest().body(result));
        }
    }
}
