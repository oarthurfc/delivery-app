package com.service.order.models;

import com.service.order.enums.OrderStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long customerId;

    @Column(nullable = true)
    private Long driverId;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    // Origin address com prefixo origin_
    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name="street", column=@Column(name="origin_street")),
            @AttributeOverride(name="number", column=@Column(name="origin_number")),
            @AttributeOverride(name="neighborhood", column=@Column(name="origin_neighborhood")),
            @AttributeOverride(name="city", column=@Column(name="origin_city")),
            @AttributeOverride(name="latitude", column=@Column(name="origin_latitude")),
            @AttributeOverride(name="longitude", column=@Column(name="origin_longitude"))
    })
    private Address originAddress;

    // Destination address com prefixo destination_
    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name="street", column=@Column(name="destination_street")),
            @AttributeOverride(name="number", column=@Column(name="destination_number")),
            @AttributeOverride(name="neighborhood", column=@Column(name="destination_neighborhood")),
            @AttributeOverride(name="city", column=@Column(name="destination_city")),
            @AttributeOverride(name="latitude", column=@Column(name="destination_latitude")),
            @AttributeOverride(name="longitude", column=@Column(name="destination_longitude"))
    })
    private Address destinationAddress;

    private String description;

    private String imageUrl;
}
