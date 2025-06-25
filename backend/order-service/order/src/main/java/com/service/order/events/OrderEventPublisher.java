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

import static com.service.order.config.RabbitMQConfig.NOTIFICATION_EXCHANGE;
import static com.service.order.config.RabbitMQConfig.ORDER_EXCHANGE;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventPublisher {

    private final RabbitTemplate rabbitTemplate;

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
    
    /**
     * Publica uma notificação de email na fila do serviço de notificações
     * quando um pedido é finalizado
     */
    public void publishEmailNotification(Order order, String customerEmail) {
        try {
            Map<String, Object> emailMessage = new HashMap<>();
            
            // Formato esperado pelo notification-service
            emailMessage.put("messageId", "order_completed_" + UUID.randomUUID().toString());
            emailMessage.put("to", customerEmail);
            emailMessage.put("type", "ORDER_COMPLETED");
            emailMessage.put("subject", "Seu pedido foi entregue!");
            emailMessage.put("template", "order_completed");
            emailMessage.put("priority", "high");
            emailMessage.put("timestamp", LocalDateTime.now().toString());
            
            // Variáveis para o template
            Map<String, Object> variables = new HashMap<>();
            variables.put("orderId", order.getId());
            variables.put("customerName", "Cliente"); // Idealmente, buscar o nome do cliente
            variables.put("orderDescription", order.getDescription());
            variables.put("deliveryAddress", formatAddress(order.getDestinationAddress()));
            variables.put("completedAt", LocalDateTime.now().toString());
            
            emailMessage.put("variables", variables);
            
            // Publicar na fila de emails usando a exchange de notificação
            rabbitTemplate.convertAndSend(NOTIFICATION_EXCHANGE, "email", emailMessage);
            
            log.info("Notificação de email publicada para pedido ID: {}", order.getId());
        } catch (Exception e) {
            log.error("Erro ao publicar notificação de email para pedido ID: {}", order.getId(), e);
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
    
    /**
     * Formata um endereço para exibição
     */
    private String formatAddress(com.service.order.models.Address address) {
        if (address == null) return "Endereço não disponível";
        
        return String.format("%s, %s - %s, %s",
            address.getStreet(),
            address.getNumber(),
            address.getNeighborhood(),
            address.getCity()
        );
    }
}