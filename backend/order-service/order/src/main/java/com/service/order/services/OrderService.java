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

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;

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

        if (dto.getDriverId() != null) order.setDriverId(dto.getDriverId());
        if (dto.getStatus() != null) order.setStatus(dto.getStatus());
        if (dto.getOriginAddress() != null) order.setOriginAddress(toAddress(dto.getOriginAddress()));
        if (dto.getDestinationAddress() != null) order.setDestinationAddress(toAddress(dto.getDestinationAddress()));
        if (dto.getDescription() != null) order.setDescription(dto.getDescription());
        if (dto.getImageUrl() != null) order.setImageUrl(dto.getImageUrl());

        Order updated = orderRepository.save(order);
        return toDTO(updated);
    }

    public void deleteOrder(Long id) {
        log.info("Deletando pedido com ID {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado com ID: " + id));
        orderRepository.delete(order);
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
        if (address == null) return null;
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
        if (dto == null) return null;
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