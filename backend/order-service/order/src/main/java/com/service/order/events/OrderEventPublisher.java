// Criar arquivo: src/main/java/com/service/order/events/OrderEventPublisher.java

package com.service.order.events;

import com.service.order.models.Order;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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
    private final DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

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
     * Publica notificação de email para cliente quando pedido é finalizado
     */
    public void publishCustomerEmailNotification(Order order, String customerEmail, String customerName) {
        publishEmailNotification(order, customerEmail, customerName, "CUSTOMER");
    }
    
    /**
     * Publica notificação de email para motorista quando pedido é finalizado
     */
    public void publishDriverEmailNotification(Order order, String driverEmail, String driverName) {
        publishEmailNotification(order, driverEmail, driverName, "DRIVER");
    }
    
    /**
     * Publica uma notificação de email na fila do serviço de notificações
     */
    private void publishEmailNotification(Order order, String email, String recipientName, String recipientType) {
        try {
            Map<String, Object> emailMessage = new HashMap<>();
            
            // Formato esperado pelo notification-service
            emailMessage.put("messageId", "order_completed_" + recipientType.toLowerCase() + "_" + UUID.randomUUID().toString());
            emailMessage.put("to", email);
            emailMessage.put("type", "ORDER_COMPLETED");
            emailMessage.put("subject", getSubjectByRecipientType(order, recipientType));
            emailMessage.put("template", "order_completed");
            emailMessage.put("priority", "high");
            emailMessage.put("timestamp", LocalDateTime.now().toString());
            
            // Variáveis para o template
            Map<String, Object> variables = createEmailVariables(order, recipientName, recipientType);
            emailMessage.put("variables", variables);
            
            // Publicar na fila de emails usando a exchange de notificação
            rabbitTemplate.convertAndSend(NOTIFICATION_EXCHANGE, "email", emailMessage);
            
            log.info("Notificação de email publicada para {} - Pedido ID: {}, Email: {}", 
                    recipientType, order.getId(), email);
        } catch (Exception e) {
            log.error("Erro ao publicar notificação de email para {} - Pedido ID: {}", 
                    recipientType, order.getId(), e);
        }
    }
    
    /**
     * Cria variáveis para o template de email
     */
    private Map<String, Object> createEmailVariables(Order order, String recipientName, String recipientType) {
        Map<String, Object> variables = new HashMap<>();
        
        // Informações básicas
        variables.put("orderId", order.getId());
        variables.put("customerName", recipientName != null ? recipientName : getDefaultName(recipientType));
        variables.put("recipientType", recipientType);
        variables.put("orderDescription", order.getDescription() != null ? order.getDescription() : "Entrega");
        
        // Endereços formatados
        variables.put("originAddress", formatAddress(order.getOriginAddress()));
        variables.put("deliveryAddress", formatAddress(order.getDestinationAddress()));
        
        // Datas formatadas
        variables.put("completedAt", LocalDateTime.now().format(dateFormatter));
        variables.put("completedAtISO", LocalDateTime.now().toString());
        
        // Informações específicas por tipo de destinatário
        if ("DRIVER".equals(recipientType)) {
            variables.put("isDriver", true);
            variables.put("customerId", order.getCustomerId());
            variables.put("pickupAddress", formatAddress(order.getOriginAddress()));
        } else {
            variables.put("isDriver", false);
            variables.put("driverId", order.getDriverId());
        }
        
        // Status e imagem
        variables.put("orderStatus", order.getStatus().toString());
        variables.put("hasImage", order.getImageUrl() != null && !order.getImageUrl().isEmpty());
        variables.put("imageUrl", order.getImageUrl());
        
        return variables;
    }
    
    /**
     * Retorna assunto do email baseado no tipo de destinatário
     */
    private String getSubjectByRecipientType(Order order, String recipientType) {
        if ("DRIVER".equals(recipientType)) {
            return "Entrega concluída - Pedido #" + order.getId();
        } else {
            return "Seu pedido foi entregue - #" + order.getId();
        }
    }
    
    /**
     * Retorna nome padrão baseado no tipo de destinatário
     */
    private String getDefaultName(String recipientType) {
        return "DRIVER".equals(recipientType) ? "Motorista" : "Cliente";
    }

    /**
     * Método público para compatibilidade (será depreciado)
     * @deprecated Use publishCustomerEmailNotification ou publishDriverEmailNotification
     */
    @Deprecated
    public void publishEmailNotification(Order order, String customerEmail) {
        publishCustomerEmailNotification(order, customerEmail, null);
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
        
        StringBuilder formatted = new StringBuilder();
        
        if (address.getStreet() != null && !address.getStreet().isEmpty()) {
            formatted.append(address.getStreet());
            
            if (address.getNumber() != null && !address.getNumber().isEmpty()) {
                formatted.append(", ").append(address.getNumber());
            }
        }
        
        if (address.getNeighborhood() != null && !address.getNeighborhood().isEmpty()) {
            if (formatted.length() > 0) formatted.append(" - ");
            formatted.append(address.getNeighborhood());
        }
        
        if (address.getCity() != null && !address.getCity().isEmpty()) {
            if (formatted.length() > 0) formatted.append(", ");
            formatted.append(address.getCity());
        }
        
        return formatted.length() > 0 ? formatted.toString() : "Endereço não disponível";
    }
}