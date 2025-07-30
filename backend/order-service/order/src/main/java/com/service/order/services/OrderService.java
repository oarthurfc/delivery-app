package com.service.order.services;

import com.service.order.dtos.*;
import com.service.order.enums.OrderStatus;
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

import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;



@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderFinishedEventPublisher orderFinishedEventPublisher;
    private final WebClient webClient = WebClient.create();
    private final SupabaseStorageService supabaseStorageService;

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

    public OrderResponseDTO completeOrder(Long id, CompleteOrderDTO completeOrderDTO, MultipartFile file) {
        log.info("Finalizando pedido com ID {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));

        if (order.getStatus() == OrderStatus.DELIVERIED) {
            throw new IllegalStateException("Pedido já está finalizado");
        }

        final String fileName = "completed_order_photo_" + id;

        String imgUrl;
        try {
            imgUrl = supabaseStorageService.uploadOrUpdateUserPhoto(file, fileName);
        } catch (IOException e) {
            log.error("Erro ao processar imagem para pedido ID {}: {}", id, e.getMessage());
            throw new RuntimeException("Erro ao processar imagem do pedido.", e);
        }

        order.setStatus(OrderStatus.DELIVERIED);
        order.setImageUrl(imgUrl);
        Order completed = orderRepository.save(order);

        OrderFinishedEventDTO eventDTO = new OrderFinishedEventDTO();
        eventDTO.setPedidoId(completed.getId());
        eventDTO.setOrigem(completed.getOriginAddress() != null ? completed.getOriginAddress().getStreet() + ", " + completed.getOriginAddress().getNumber() : null);
        eventDTO.setDestino(completed.getDestinationAddress() != null ? completed.getDestinationAddress().getStreet() + ", " + completed.getDestinationAddress().getNumber() : null);
        eventDTO.setDescricao(completed.getDescription());
        eventDTO.setDestinatario(null);
        eventDTO.setPreco(null);
        eventDTO.setClienteEmail(completeOrderDTO.getClienteEmail());
        eventDTO.setMotoristaEmail(completeOrderDTO.getMotoristaEmail());
        eventDTO.setFcmToken(completeOrderDTO.getFcmToken());

        orderFinishedEventPublisher.publish(eventDTO);
        return toDTO(completed);
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