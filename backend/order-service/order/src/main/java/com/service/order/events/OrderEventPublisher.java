// Criar arquivo: src/main/java/com/service/order/events/OrderEventPublisher.java

package com.service.order.events;

import com.service.order.models.Order;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventPublisher {

    private final RabbitTemplate rabbitTemplate;
    private static final String ORDER_EXCHANGE = "order.exchange";

    public void publishOrderCompleted(Order order) {
        try {
            Map<String, Object> event = createOrderEvent(order, "ORDER_COMPLETED");
            
            rabbitTemplate.convertAndSend(ORDER_EXCHANGE, "order.completed", event);
            
            log.info("Evento ORDER_COMPLETED publicado para pedido ID: {}", order.getId());
        } catch (Exception e) {
            log.error("Erro ao publicar evento ORDER_COMPLETED para pedido ID: {}", order.getId(), e);
        }
    }

    public void publishOrderCreated(Order order) {
        try {
            Map<String, Object> event = createOrderEvent(order, "ORDER_CREATED");
            
            rabbitTemplate.convertAndSend(ORDER_EXCHANGE, "order.created", event);
            
            log.info("Evento ORDER_CREATED publicado para pedido ID: {}", order.getId());
        } catch (Exception e) {
            log.error("Erro ao publicar evento ORDER_CREATED para pedido ID: {}", order.getId(), e);
        }
    }

    private Map<String, Object> createOrderEvent(Order order, String eventType) {
        Map<String, Object> event = new HashMap<>();
        
        // Metadados do evento
        event.put("eventId", UUID.randomUUID().toString());
        event.put("eventType", eventType);
        event.put("timestamp", LocalDateTime.now());
        
        // Dados do pedido
        event.put("orderId", order.getId());
        event.put("customerId", order.getCustomerId());
        event.put("driverId", order.getDriverId());
        event.put("status", order.getStatus().toString());
        event.put("description", order.getDescription());
        event.put("imageUrl", order.getImageUrl());
        
        // Endereços
        if (order.getOriginAddress() != null) {
            Map<String, Object> origin = new HashMap<>();
            origin.put("street", order.getOriginAddress().getStreet());
            origin.put("number", order.getOriginAddress().getNumber());
            origin.put("neighborhood", order.getOriginAddress().getNeighborhood());
            origin.put("city", order.getOriginAddress().getCity());
            origin.put("latitude", order.getOriginAddress().getLatitude());
            origin.put("longitude", order.getOriginAddress().getLongitude());
            event.put("originAddress", origin);
        }
        
        if (order.getDestinationAddress() != null) {
            Map<String, Object> destination = new HashMap<>();
            destination.put("street", order.getDestinationAddress().getStreet());
            destination.put("number", order.getDestinationAddress().getNumber());
            destination.put("neighborhood", order.getDestinationAddress().getNeighborhood());
            destination.put("city", order.getDestinationAddress().getCity());
            destination.put("latitude", order.getDestinationAddress().getLatitude());
            destination.put("longitude", order.getDestinationAddress().getLongitude());
            event.put("destinationAddress", destination);
        }
        
        return event;
    }
}