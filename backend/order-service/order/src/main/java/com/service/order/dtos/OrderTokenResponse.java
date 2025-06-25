package com.service.order.dtos;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class OrderTokenResponse {
    private Long id;
    private String name;
    private String email;
    private String fcmToken;
    private String role;
    private boolean active;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
