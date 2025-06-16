package com.service.order.dtos;

import com.service.order.enums.OrderStatus;

import lombok.Data;

@Data
public class CreateOrderDTO {
    private Long customerId;
    private Long driverId; // pode ser null inicialmente
    private OrderStatus status;
    private AddressDTO originAddress;
    private AddressDTO destinationAddress;
    private String description;
    private String imageUrl;
}
