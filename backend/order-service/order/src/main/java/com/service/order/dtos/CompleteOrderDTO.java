package com.service.order.dtos;

import lombok.Data;

@Data
public class CompleteOrderDTO {
    private String clienteEmail;
    private String motoristaEmail;
    private String fcmToken;
    // Adicione outros campos recebidos no body, se necessário
}