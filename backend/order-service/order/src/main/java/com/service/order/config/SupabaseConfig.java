package com.service.order.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class SupabaseConfig {

    @Value("${supabase.api-key}")
    private String supabaseApiKey;

    @Value("${supabase.code}")
    private String supabaseCode;

    @Bean(name = "supabaseWebClient")
    public WebClient supabaseWebClient(WebClient.Builder builder) {
        String baseUrl = "https://" + supabaseCode + ".supabase.co";

        return builder.baseUrl(baseUrl)
                .defaultHeader("apikey", supabaseApiKey)
                .defaultHeader("Authorization", "Bearer " + supabaseApiKey)
                .build();
    }
}