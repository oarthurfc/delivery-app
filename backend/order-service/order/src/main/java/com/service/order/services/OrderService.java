package com.service.order.services;

import com.service.order.dtos.*;
import com.service.order.enums.OrderStatus;
import com.service.order.events.OrderEventPublisher;
import com.service.order.models.Order;
import com.service.order.models.Address;
import com.service.order.repositories.OrderRepository;
import com.service.order.exceptions.ResourceNotFoundException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.data.domain.PageImpl;
import org.springframework.stereotype.Service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderEventPublisher eventPublisher;
    private final WebClient webClient = WebClient.create();

    public OrderResponseDTO createOrder(CreateOrderDTO dto) {
        log.info("Criando novo pedido para o cliente ID {}", dto.getCustomerId());

        Order order = new Order();
        order.setCustomerId(dto.getCustomerId());
        order.setDriverId(dto.getDriverId());
        order.setStatus(dto.getStatus() != null ? dto.getStatus() : OrderStatus.PENDING);
        order.setOriginAddress(toAddress(dto.getOriginAddress()));
        order.setDestinationAddress(toAddress(dto.getDestinationAddress()));
        order.setDescription(dto.getDescription());
        order.setImageUrl(dto.getImageUrl());

        Order saved = orderRepository.save(order);
        return toDTO(saved);
    }

    public Page<OrderResponseDTO> getAllOrders(final Pageable pageable) {
        log.info("Buscando todos os pedidos com paginação");

        Page<Order> ordersPage = orderRepository.findAll(pageable);

        List<OrderResponseDTO> dtos = ordersPage
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());

        return new PageImpl<>(dtos, pageable, ordersPage.getTotalElements());
    }

    public OrderResponseDTO getOrderById(Long id) {
        log.info("Buscando pedido com ID {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));
        return toDTO(order);
    }

    public OrderResponseDTO updateOrder(Long id, UpdateOrderDTO dto) {
        log.info("Atualizando pedido com ID {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));

        if (dto.getDriverId() != null)
            order.setDriverId(dto.getDriverId());
        if (dto.getStatus() != null)
            order.setStatus(dto.getStatus());
        if (dto.getOriginAddress() != null)
            order.setOriginAddress(toAddress(dto.getOriginAddress()));
        if (dto.getDestinationAddress() != null)
            order.setDestinationAddress(toAddress(dto.getDestinationAddress()));
        if (dto.getDescription() != null)
            order.setDescription(dto.getDescription());
        if (dto.getImageUrl() != null)
            order.setImageUrl(dto.getImageUrl());

        Order updated = orderRepository.save(order);
        return toDTO(updated);
    }

    public void deleteOrder(Long id) {
        log.info("Deletando pedido com ID {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));
        orderRepository.delete(order);
    }

    public List<OrderResponseDTO> getOrdersByDriverId(Long driverId) {
        log.info("Buscando pedidos do motorista com ID {}", driverId);
        List<Order> orders = orderRepository.findByDriverId(driverId);
        return orders.stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public Page<OrderResponseDTO> getOrdersByDriverId(Long driverId, Pageable pageable) {
        log.info("Buscando pedidos do motorista com ID {} (paginado)", driverId);
        Page<Order> ordersPage = orderRepository.findByDriverId(driverId, pageable);

        List<OrderResponseDTO> dtos = ordersPage
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());

        return new PageImpl<>(dtos, pageable, ordersPage.getTotalElements());
    }

    public OrderResponseDTO completeOrder(Long id, String imageUrl) {
    log.info("Finalizando pedido com ID {}", id);
    Order order = orderRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));

    if (order.getStatus() == OrderStatus.DELIVERIED) {
        throw new IllegalStateException("Pedido já está finalizado");
    }

    order.setStatus(OrderStatus.DELIVERIED);
    order.setImageUrl(imageUrl);
    Order completed = orderRepository.save(order);

    // Publicar evento de finalização
    eventPublisher.publishOrderCompleted(completed);

    // Buscar informações do cliente e motorista no serviço de autenticação
    String customerEmail = getCustomerEmail(completed.getCustomerId());
    String customerName = getCustomerName(completed.getCustomerId()); // Novo método para buscar nome
    
    String motoristaEmail = getCustomerEmail(completed.getDriverId());
    String motoristaName = getCustomerName(completed.getDriverId()); // Novo método para buscar nome

    // Publicar notificações de email específicas para cliente e motorista
    if (customerEmail != null && !customerEmail.isEmpty()) {
        eventPublisher.publishCustomerEmailNotification(completed, customerEmail, customerName);
        log.info("Notificação de email enviada para cliente ID: {}, Email: {}", 
                completed.getCustomerId(), customerEmail);
    } else {
        log.warn("Não foi possível enviar notificação de email para cliente ID: {}, email não encontrado",
                completed.getCustomerId());
    }
    
    if (motoristaEmail != null && !motoristaEmail.isEmpty()) {
        eventPublisher.publishDriverEmailNotification(completed, motoristaEmail, motoristaName);
        log.info("Notificação de email enviada para motorista ID: {}, Email: {}", 
                completed.getDriverId(), motoristaEmail);
    } else {
        log.warn("Não foi possível enviar notificação de email para motorista ID: {}, email não encontrado",
                completed.getDriverId());
    }
    
    // Enviar push notifications
    sendPushNotification(completed);
    
    return toDTO(completed);
}

/**
 * Método auxiliar para buscar nome do usuário (cliente ou motorista)
 * Implementar conforme sua integração com o serviço de autenticação
 */
private String getCustomerName(Long userId) {
    try {
        // Implementar chamada para o serviço de autenticação para buscar o nome
        // Exemplo:
        // UserInfo userInfo = authServiceClient.getUserById(userId);
        // return userInfo.getName();
        
        // Por enquanto, retornar null para usar o valor padrão nos templates
        return "Renato";
    } catch (Exception e) {
        log.warn("Erro ao buscar nome do usuário ID: {}", userId, e);
        return null;
    }
}
    private String getFcmTokenFromOrder(Long orderId) {
        try {
            String url = "http://api-gateway:8000/api/auth/user/"+ orderId;
    
            OrderTokenResponse response = webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(OrderTokenResponse.class)
                .block();
            
                log.info("FcmToken encontrado: {}", response.getFcmToken());
            return response != null ? response.getFcmToken() : null;
        } catch (Exception e) {
            log.error("Erro ao buscar fcmToken para o pedido {}", orderId, e);
            return null;
        }
    }
    

    private void sendPushNotification(Order completed) {
        log.info("Enviando notificação push para o cliente ID: {}", completed.getCustomerId());

        try {
            //String fcmToken = "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH-DQ8yon4UfFS4G8-Kkw1o9-s1XNepEemwdvAFgQ7jEOz5K_ziG1iJ8Y";
            String fcmToken = getFcmTokenFromOrder(completed.getCustomerId());
            String title = "Pedido Finalizado!";
            String body = "Seu pedido #" + completed.getId() + " foi recebido com sucesso!";
        
            var payload = new PushNotificationPayload(fcmToken, title, body);
        
            webClient.post()
                .uri("http://192.168.0.21:7071/api/PushNotificationFunction")
                .bodyValue(payload)
                .retrieve()
                .bodyToMono(Void.class)
                .block();
        
            log.info("Push notification enviada com sucesso para pedido ID: {}", completed.getId());
        } catch (Exception e) {
            log.error("Erro ao enviar push notification para pedido ID: {}", completed.getId(), e);
        }
        // Implementar a lógica para enviar notificação push
    }// Requisição para a Azure Function de Push Notification



    /**
     * Busca o email do cliente no serviço de autenticação
     * Este método pode ser implementado utilizando o auth-service
     */
    private String getCustomerEmail(Long customerId) {
        try {
            log.info("Buscando email do cliente ID: {}", customerId);

            // Em um ambiente real, fariamos uma chamada ao auth-service para obter o email
            // Exemplo:
            /*
             * UserDto user = webClient.get()
             * .uri("http://auth-service/api/users/" + customerId)
             * .retrieve()
             * .bodyToMono(UserDto.class)
             * .block();
             * return user.getEmail();
             */

            // Para fins de demonstração, estamos retornando um email falso
            // IMPORTANTE: Implementar mais tarde a integração real com o auth-service

            return "cliente" + customerId + "@example.com";

        } catch (Exception e) {
            log.error("Erro ao buscar email do cliente ID: {}", customerId, e);
            return null;
        }
    }

    // -----------------------
    // Métodos auxiliares
    // -----------------------

    private OrderResponseDTO toDTO(Order order) {
        OrderResponseDTO dto = new OrderResponseDTO();
        dto.setId(order.getId());
        dto.setCustomerId(order.getCustomerId());
        dto.setDriverId(order.getDriverId());
        dto.setStatus(order.getStatus());
        dto.setOriginAddress(toAddressDTO(order.getOriginAddress()));
        dto.setDestinationAddress(toAddressDTO(order.getDestinationAddress()));
        dto.setDescription(order.getDescription());
        dto.setImageUrl(order.getImageUrl());
        return dto;
    }

    private AddressDTO toAddressDTO(Address address) {
        if (address == null)
            return null;
        AddressDTO dto = new AddressDTO();
        dto.setStreet(address.getStreet());
        dto.setNumber(address.getNumber());
        dto.setNeighborhood(address.getNeighborhood());
        dto.setCity(address.getCity());
        dto.setLatitude(address.getLatitude());
        dto.setLongitude(address.getLongitude());
        return dto;
    }

    private Address toAddress(AddressDTO dto) {
        if (dto == null)
            return null;
        Address address = new Address();
        address.setStreet(dto.getStreet());
        address.setNumber(dto.getNumber());
        address.setNeighborhood(dto.getNeighborhood());
        address.setCity(dto.getCity());
        address.setLatitude(dto.getLatitude());
        address.setLongitude(dto.getLongitude());
        return address;
    }
}