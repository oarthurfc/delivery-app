package com.service.order.dtos;

import com.service.order.enums.OrderStatus;
import lombok.Data;

@Data
public class OrderResponseDTO {
    private Long id;
    private Long customerId;
    private Long driverId;
    private OrderStatus status;
    private AddressDTO originAddress;
    private AddressDTO destinationAddress;
    private String description;
    private String imageUrl;
}
