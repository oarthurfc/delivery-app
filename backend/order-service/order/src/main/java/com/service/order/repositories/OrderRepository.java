package com.service.order.repositories;

import com.service.order.models.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByDriverId(Long driverId);
    Page<Order> findByDriverId(Long driverId, Pageable pageable);
}
