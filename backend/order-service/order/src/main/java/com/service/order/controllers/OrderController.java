package com.service.order.controllers;

import com.service.order.dtos.*;
import com.service.order.services.OrderService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.web.multipart.MultipartFile;

import org.springframework.http.MediaType;





@Slf4j
@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<OrderResponseDTO> create(@Valid @RequestBody CreateOrderDTO dto) {
        log.info("Recebida requisição para criar novo pedido");
        OrderResponseDTO created = orderService.createOrder(dto);
        return ResponseEntity.created(URI.create("/api/orders/" + created.getId())).body(created);
    }

    @GetMapping("/ok")
    public String ok() {
        return "OK";
    }

    @GetMapping
    public ResponseEntity<Page<OrderResponseDTO>> getAll(final Pageable pageable) {
        log.info("Recebida requisição para listar todos os pedidos");
        return ResponseEntity.ok(orderService.getAllOrders(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponseDTO> getById(@PathVariable Long id) {
        log.info("Recebida requisição para buscar pedido ID {}", id);
        return ResponseEntity.ok(orderService.getOrderById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrderResponseDTO> update(@PathVariable Long id, @Valid @RequestBody UpdateOrderDTO dto) {
        log.info("Recebida requisição para atualizar pedido ID {}", id);
        return ResponseEntity.ok(orderService.updateOrder(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        log.info("Recebida requisição para deletar pedido ID {}", id);
        orderService.deleteOrder(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<List<OrderResponseDTO>> getByDriverId(@PathVariable Long driverId) {
        log.info("Recebida requisição para buscar pedidos do motorista ID {}", driverId);
        return ResponseEntity.ok(orderService.getOrdersByDriverId(driverId));
    }

    @GetMapping("/driver/{driverId}/paged")
    public ResponseEntity<Page<OrderResponseDTO>> getByDriverIdPaged(
            @PathVariable Long driverId,
            final Pageable pageable) {
        log.info("Recebida requisição para buscar pedidos paginados do motorista ID {}", driverId);
        return ResponseEntity.ok(orderService.getOrdersByDriverId(driverId, pageable));
    }

    @PutMapping(path = "/{id}/complete", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<OrderResponseDTO> complete(
            @PathVariable Long id,
            @RequestPart("data") @Valid CompleteOrderDTO completeOrderDTO,
            @RequestPart("file") MultipartFile file) {
        log.info("Recebida requisição para finalizar pedido ID {}", id);
        return ResponseEntity.ok(orderService.completeOrder(id, completeOrderDTO, file));
    }
}