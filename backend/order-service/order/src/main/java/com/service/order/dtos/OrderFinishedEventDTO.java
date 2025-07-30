package com.service.order.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderFinishedEventDTO {
    private Long pedidoId;
    private String origem;
    private String destino;
    private String descricao;
    private String destinatario;
    private Double preco;
    private String clienteEmail;
    private String motoristaEmail;
    private String fcmToken;
    private String title;
    private String body;
} 
