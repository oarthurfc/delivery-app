package com.service.order.services;

import org.springframework.stereotype.Service;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.service.order.dtos.OrderFinishedEventDTO;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class OrderFinishedEventPublisher {

    private final ServiceBusSenderClient senderClient;
    private final ObjectMapper objectMapper;

    public OrderFinishedEventPublisher(ServiceBusSenderClient senderClient, ObjectMapper objectMapper) {
        this.senderClient = senderClient;
        this.objectMapper = objectMapper;
    }

    public void publish(OrderFinishedEventDTO eventDTO) {
        log.info("Publicando evento de pedido finalizado: {}", eventDTO);
        try {
            String json = objectMapper.writeValueAsString(eventDTO);
            senderClient.sendMessage(new ServiceBusMessage(json));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Erro ao serializar o evento de pedido finalizado", e);
        }
    }
}
