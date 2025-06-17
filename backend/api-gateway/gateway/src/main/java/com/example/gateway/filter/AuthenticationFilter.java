package com.example.gateway.filter;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.util.Map;

@Component
public class AuthenticationFilter extends AbstractGatewayFilterFactory<AuthenticationFilter.Config> {

    private final WebClient.Builder webClientBuilder;

    public AuthenticationFilter(WebClient.Builder webClientBuilder) {
        super(Config.class);
        this.webClientBuilder = webClientBuilder;
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            if (!exchange.getRequest().getHeaders().containsKey(HttpHeaders.AUTHORIZATION)) {
                return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing authorization header"));
            }

            String authHeader = exchange.getRequest().getHeaders().get(HttpHeaders.AUTHORIZATION).get(0);
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid authorization header"));
            }

            return validateToken(authHeader)
                    .flatMap(userData -> {
                        // Adiciona informações do usuário no header para os serviços downstream
                        exchange.getRequest().mutate()
                                .header("X-Auth-User-Id", userData.get("userId").toString())
                                .header("X-Auth-User-Role", userData.get("role").toString());
                        return chain.filter(exchange);
                    })
                    .onErrorResume(error -> 
                        Mono.error(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token"))
                    );
        };
    }

    private Mono<Map<String, Object>> validateToken(String token) {
        return webClientBuilder.build()
                .post()
                .uri("http://auth-service:3000/api/auth/validate")
                .header(HttpHeaders.AUTHORIZATION, token)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {});
    }

    public static class Config {
        // Configuração vazia, pode ser estendida se necessário
    }
}
