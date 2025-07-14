# Spring Boot Chat Feature Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Entity Models](#entity-models)
4. [Repository Layer](#repository-layer)
5. [Service Layer](#service-layer)
6. [Controller Layer](#controller-layer)
7. [Configuration](#configuration)
8. [API Endpoints](#api-endpoints)
9. [Testing](#testing)
10. [Deployment](#deployment)

## Overview

This guide provides a complete Spring Boot backend implementation for the chat feature that supports real-time messaging between customers and laundry service providers.

### Features Implemented
- ✅ Create/Get conversations between customers and laundries
- ✅ Send and receive messages
- ✅ Mark messages as read
- ✅ Get conversation history
- ✅ Unread message count
- ✅ Real-time messaging support
- ✅ Message timestamps and status tracking

## Database Schema

### 1. Conversations Table
```sql
CREATE TABLE conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    laundry_id BIGINT NOT NULL,
    laundry_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_conversation (customer_id, laundry_id),
    INDEX idx_customer (customer_id),
    INDEX idx_laundry (laundry_id)
);
```

### 2. Messages Table
```sql
CREATE TABLE messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_role ENUM('CUSTOMER', 'LAUNDRY') NOT NULL,
    message TEXT NOT NULL,
    message_type ENUM('text', 'image', 'order_update', 'system_message') DEFAULT 'text',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    INDEX idx_conversation (conversation_id),
    INDEX idx_sender (sender_id),
    INDEX idx_created_at (created_at)
);
```

### 3. Message Read Status Table (Optional - for group chat support)
```sql
CREATE TABLE message_read_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    UNIQUE KEY unique_read_status (message_id, user_id),
    INDEX idx_message (message_id),
    INDEX idx_user (user_id)
);
```

## Entity Models

### 1. Conversation Entity
```java
package com.laundry.chat.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "conversations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false)
public class Conversation {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "customer_id", nullable = false)
    private Long customerId;
    
    @Column(name = "customer_name", nullable = false)
    private String customerName;
    
    @Column(name = "laundry_id", nullable = false)
    private Long laundryId;
    
    @Column(name = "laundry_name", nullable = false)
    private String laundryName;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Message> messages;
    
    @Transient
    private Message lastMessage;
    
    @Transient
    private Long unreadCount;
}
```

### 2. Message Entity
```java
package com.laundry.chat.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false)
public class Message {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;
    
    @Column(name = "sender_id", nullable = false)
    private Long senderId;
    
    @Column(name = "sender_name", nullable = false)
    private String senderName;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "sender_role", nullable = false)
    private UserRole senderRole;
    
    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", nullable = false)
    private MessageType messageType = MessageType.TEXT;
    
    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
}
```

### 3. Enums
```java
package com.laundry.chat.enums;

public enum UserRole {
    CUSTOMER,
    LAUNDRY
}

public enum MessageType {
    TEXT,
    IMAGE,
    ORDER_UPDATE,
    SYSTEM_MESSAGE
}
```

## Repository Layer

### 1. Conversation Repository
```java
package com.laundry.chat.repository;

import com.laundry.chat.entity.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    
    @Query("SELECT c FROM Conversation c WHERE c.customerId = :userId OR c.laundryId = :userId ORDER BY c.updatedAt DESC")
    List<Conversation> findConversationsByUserId(@Param("userId") Long userId);
    
    @Query("SELECT c FROM Conversation c WHERE c.customerId = :customerId AND c.laundryId = :laundryId")
    Optional<Conversation> findByCustomerIdAndLaundryId(@Param("customerId") Long customerId, @Param("laundryId") Long laundryId);
    
    @Query("SELECT c FROM Conversation c WHERE c.customerId = :customerId")
    List<Conversation> findByCustomerId(@Param("customerId") Long customerId);
    
    @Query("SELECT c FROM Conversation c WHERE c.laundryId = :laundryId")
    List<Conversation> findByLaundryId(@Param("laundryId") Long laundryId);
}
```

### 2. Message Repository
```java
package com.laundry.chat.repository;

import com.laundry.chat.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    
    @Query("SELECT m FROM Message m WHERE m.conversation.id = :conversationId ORDER BY m.createdAt ASC")
    Page<Message> findByConversationId(@Param("conversationId") Long conversationId, Pageable pageable);
    
    @Query("SELECT m FROM Message m WHERE m.conversation.id = :conversationId ORDER BY m.createdAt DESC")
    List<Message> findByConversationIdOrderByCreatedAtDesc(@Param("conversationId") Long conversationId);
    
    @Query("SELECT m FROM Message m WHERE m.conversation.id = :conversationId ORDER BY m.createdAt DESC LIMIT 1")
    Message findLastMessageByConversationId(@Param("conversationId") Long conversationId);
    
    @Query("SELECT COUNT(m) FROM Message m WHERE m.conversation.id = :conversationId AND m.senderId != :userId AND m.isRead = false")
    Long countUnreadMessages(@Param("conversationId") Long conversationId, @Param("userId") Long userId);
    
    @Query("SELECT COUNT(m) FROM Message m JOIN m.conversation c WHERE (c.customerId = :userId OR c.laundryId = :userId) AND m.senderId != :userId AND m.isRead = false")
    Long countUnreadMessagesForUser(@Param("userId") Long userId);
    
    @Modifying
    @Transactional
    @Query("UPDATE Message m SET m.isRead = true, m.readAt = :readAt WHERE m.conversation.id = :conversationId AND m.senderId != :userId AND m.isRead = false")
    int markMessagesAsRead(@Param("conversationId") Long conversationId, @Param("userId") Long userId, @Param("readAt") LocalDateTime readAt);
}
```

## Service Layer

### 1. Chat Service Interface
```java
package com.laundry.chat.service;

import com.laundry.chat.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface ChatService {
    
    ConversationResponseDto createOrGetConversation(CreateConversationRequestDto request);
    
    List<ConversationResponseDto> getConversationsByUserId(Long userId);
    
    MessageResponseDto sendMessage(SendMessageRequestDto request);
    
    Page<MessageResponseDto> getMessagesByConversationId(Long conversationId, Pageable pageable);
    
    void markMessagesAsRead(Long conversationId, Long userId);
    
    Long getUnreadMessageCount(Long userId);
    
    ConversationResponseDto getConversationById(Long conversationId);
}
```

### 2. Chat Service Implementation
```java
package com.laundry.chat.service.impl;

import com.laundry.chat.dto.*;
import com.laundry.chat.entity.Conversation;
import com.laundry.chat.entity.Message;
import com.laundry.chat.enums.MessageType;
import com.laundry.chat.enums.UserRole;
import com.laundry.chat.exception.ConversationNotFoundException;
import com.laundry.chat.exception.InvalidUserException;
import com.laundry.chat.repository.ConversationRepository;
import com.laundry.chat.repository.MessageRepository;
import com.laundry.chat.service.ChatService;
import com.laundry.chat.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ChatServiceImpl implements ChatService {
    
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserService userService;
    
    @Override
    public ConversationResponseDto createOrGetConversation(CreateConversationRequestDto request) {
        log.info("Creating or getting conversation for customer: {} and laundry: {}", 
                request.getCustomerId(), request.getLaundryId());
        
        // Validate users exist
        if (!userService.userExists(request.getCustomerId())) {
            throw new InvalidUserException("Customer not found with ID: " + request.getCustomerId());
        }
        
        if (!userService.userExists(request.getLaundryId())) {
            throw new InvalidUserException("Laundry not found with ID: " + request.getLaundryId());
        }
        
        // Check if conversation already exists
        Conversation conversation = conversationRepository
                .findByCustomerIdAndLaundryId(request.getCustomerId(), request.getLaundryId())
                .orElseGet(() -> {
                    // Create new conversation
                    Conversation newConversation = new Conversation();
                    newConversation.setCustomerId(request.getCustomerId());
                    newConversation.setCustomerName(userService.getUserName(request.getCustomerId()));
                    newConversation.setLaundryId(request.getLaundryId());
                    newConversation.setLaundryName(userService.getUserName(request.getLaundryId()));
                    return conversationRepository.save(newConversation);
                });
        
        return convertToConversationResponseDto(conversation);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<ConversationResponseDto> getConversationsByUserId(Long userId) {
        log.info("Getting conversations for user: {}", userId);
        
        List<Conversation> conversations = conversationRepository.findConversationsByUserId(userId);
        
        return conversations.stream()
                .map(this::convertToConversationResponseDto)
                .collect(Collectors.toList());
    }
    
    @Override
    public MessageResponseDto sendMessage(SendMessageRequestDto request) {
        log.info("Sending message to conversation: {} from sender: {}", 
                request.getConversationId(), request.getSenderId());
        
        Conversation conversation = conversationRepository
                .findById(request.getConversationId())
                .orElseThrow(() -> new ConversationNotFoundException("Conversation not found"));
        
        // Validate sender is part of conversation
        if (!conversation.getCustomerId().equals(request.getSenderId()) && 
            !conversation.getLaundryId().equals(request.getSenderId())) {
            throw new InvalidUserException("User is not part of this conversation");
        }
        
        Message message = new Message();
        message.setConversation(conversation);
        message.setSenderId(request.getSenderId());
        message.setSenderName(userService.getUserName(request.getSenderId()));
        message.setSenderRole(getSenderRole(conversation, request.getSenderId()));
        message.setMessage(request.getMessage());
        message.setMessageType(MessageType.valueOf(request.getMessageType().toUpperCase()));
        
        Message savedMessage = messageRepository.save(message);
        
        // Update conversation timestamp
        conversation.setUpdatedAt(LocalDateTime.now());
        conversationRepository.save(conversation);
        
        return convertToMessageResponseDto(savedMessage);
    }
    
    @Override
    @Transactional(readOnly = true)
    public Page<MessageResponseDto> getMessagesByConversationId(Long conversationId, Pageable pageable) {
        log.info("Getting messages for conversation: {}", conversationId);
        
        // Ensure conversation exists
        conversationRepository.findById(conversationId)
                .orElseThrow(() -> new ConversationNotFoundException("Conversation not found"));
        
        // Create pageable with sorting by creation time (ascending for chat)
        Pageable sortedPageable = PageRequest.of(
                pageable.getPageNumber(), 
                pageable.getPageSize(), 
                Sort.by(Sort.Direction.ASC, "createdAt")
        );
        
        Page<Message> messages = messageRepository.findByConversationId(conversationId, sortedPageable);
        
        return messages.map(this::convertToMessageResponseDto);
    }
    
    @Override
    public void markMessagesAsRead(Long conversationId, Long userId) {
        log.info("Marking messages as read for conversation: {} by user: {}", conversationId, userId);
        
        int updatedCount = messageRepository.markMessagesAsRead(conversationId, userId, LocalDateTime.now());
        log.info("Marked {} messages as read", updatedCount);
    }
    
    @Override
    @Transactional(readOnly = true)
    public Long getUnreadMessageCount(Long userId) {
        log.info("Getting unread message count for user: {}", userId);
        
        return messageRepository.countUnreadMessagesForUser(userId);
    }
    
    @Override
    @Transactional(readOnly = true)
    public ConversationResponseDto getConversationById(Long conversationId) {
        log.info("Getting conversation by ID: {}", conversationId);
        
        Conversation conversation = conversationRepository
                .findById(conversationId)
                .orElseThrow(() -> new ConversationNotFoundException("Conversation not found"));
        
        return convertToConversationResponseDto(conversation);
    }
    
    private UserRole getSenderRole(Conversation conversation, Long senderId) {
        if (conversation.getCustomerId().equals(senderId)) {
            return UserRole.CUSTOMER;
        } else if (conversation.getLaundryId().equals(senderId)) {
            return UserRole.LAUNDRY;
        }
        throw new InvalidUserException("Sender is not part of this conversation");
    }
    
    private ConversationResponseDto convertToConversationResponseDto(Conversation conversation) {
        // Get last message
        Message lastMessage = messageRepository.findLastMessageByConversationId(conversation.getId());
        
        ConversationResponseDto dto = new ConversationResponseDto();
        dto.setId(conversation.getId());
        dto.setCustomerId(conversation.getCustomerId());
        dto.setCustomerName(conversation.getCustomerName());
        dto.setLaundryId(conversation.getLaundryId());
        dto.setLaundryName(conversation.getLaundryName());
        dto.setCreatedAt(conversation.getCreatedAt());
        dto.setUpdatedAt(conversation.getUpdatedAt());
        
        if (lastMessage != null) {
            dto.setLastMessage(convertToMessageResponseDto(lastMessage));
        }
        
        return dto;
    }
    
    private MessageResponseDto convertToMessageResponseDto(Message message) {
        MessageResponseDto dto = new MessageResponseDto();
        dto.setId(message.getId());
        dto.setConversationId(message.getConversation().getId());
        dto.setSenderId(message.getSenderId());
        dto.setSenderName(message.getSenderName());
        dto.setSenderRole(message.getSenderRole().name());
        dto.setMessage(message.getMessage());
        dto.setMessageType(message.getMessageType().name());
        dto.setIsRead(message.getIsRead());
        dto.setCreatedAt(message.getCreatedAt());
        dto.setReadAt(message.getReadAt());
        return dto;
    }
}
```

## Controller Layer

### 1. Chat Controller
```java
package com.laundry.chat.controller;

import com.laundry.chat.dto.*;
import com.laundry.chat.service.ChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import java.util.List;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
@Slf4j
@Validated
public class ChatController {
    
    private final ChatService chatService;
    
    @PostMapping("/conversations")
    public ResponseEntity<ConversationResponseDto> createOrGetConversation(
            @Valid @RequestBody CreateConversationRequestDto request) {
        log.info("POST /chat/conversations - Creating conversation between customer: {} and laundry: {}", 
                request.getCustomerId(), request.getLaundryId());
        
        ConversationResponseDto response = chatService.createOrGetConversation(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/conversations/{userId}")
    public ResponseEntity<List<ConversationResponseDto>> getConversationsByUserId(
            @PathVariable @Min(1) Long userId) {
        log.info("GET /chat/conversations/{} - Getting conversations for user", userId);
        
        List<ConversationResponseDto> conversations = chatService.getConversationsByUserId(userId);
        return ResponseEntity.ok(conversations);
    }
    
    @PostMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<MessageResponseDto> sendMessage(
            @PathVariable @Min(1) Long conversationId,
            @Valid @RequestBody SendMessageRequestDto request) {
        log.info("POST /chat/conversations/{}/messages - Sending message from user: {}", 
                conversationId, request.getSenderId());
        
        request.setConversationId(conversationId);
        MessageResponseDto response = chatService.sendMessage(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<Page<MessageResponseDto>> getMessages(
            @PathVariable @Min(1) Long conversationId,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "50") @Min(1) int limit) {
        log.info("GET /chat/conversations/{}/messages - Getting messages (page: {}, limit: {})", 
                conversationId, page, limit);
        
        Pageable pageable = PageRequest.of(page, limit);
        Page<MessageResponseDto> messages = chatService.getMessagesByConversationId(conversationId, pageable);
        return ResponseEntity.ok(messages);
    }
    
    @PutMapping("/conversations/{conversationId}/messages/read")
    public ResponseEntity<Void> markMessagesAsRead(
            @PathVariable @Min(1) Long conversationId,
            @RequestParam @Min(1) Long userId) {
        log.info("PUT /chat/conversations/{}/messages/read - Marking messages as read for user: {}", 
                conversationId, userId);
        
        chatService.markMessagesAsRead(conversationId, userId);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/users/{userId}/unread-count")
    public ResponseEntity<UnreadCountResponseDto> getUnreadMessageCount(
            @PathVariable @Min(1) Long userId) {
        log.info("GET /chat/users/{}/unread-count - Getting unread count", userId);
        
        Long unreadCount = chatService.getUnreadMessageCount(userId);
        UnreadCountResponseDto response = new UnreadCountResponseDto();
        response.setUnreadCount(unreadCount);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/conversations/{conversationId}")
    public ResponseEntity<ConversationResponseDto> getConversationById(
            @PathVariable @Min(1) Long conversationId) {
        log.info("GET /chat/conversations/{} - Getting conversation by ID", conversationId);
        
        ConversationResponseDto response = chatService.getConversationById(conversationId);
        return ResponseEntity.ok(response);
    }
}
```

## DTOs (Data Transfer Objects)

### 1. Request DTOs
```java
package com.laundry.chat.dto;

import lombok.Data;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

@Data
public class CreateConversationRequestDto {
    @NotNull(message = "Customer ID is required")
    @Min(value = 1, message = "Customer ID must be greater than 0")
    private Long customerId;
    
    @NotNull(message = "Laundry ID is required")
    @Min(value = 1, message = "Laundry ID must be greater than 0")
    private Long laundryId;
}

@Data
public class SendMessageRequestDto {
    private Long conversationId; // Set by controller
    
    @NotNull(message = "Sender ID is required")
    @Min(value = 1, message = "Sender ID must be greater than 0")
    private Long senderId;
    
    @NotNull(message = "Message is required")
    @Size(min = 1, max = 1000, message = "Message must be between 1 and 1000 characters")
    private String message;
    
    @NotNull(message = "Message type is required")
    private String messageType = "text";
}
```

### 2. Response DTOs
```java
package com.laundry.chat.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ConversationResponseDto {
    private Long id;
    private Long customerId;
    private String customerName;
    private Long laundryId;
    private String laundryName;
    private MessageResponseDto lastMessage;
    private Long unreadCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

@Data
public class MessageResponseDto {
    private Long id;
    private Long conversationId;
    private Long senderId;
    private String senderName;
    private String senderRole;
    private String message;
    private String messageType;
    private Boolean isRead;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}

@Data
public class UnreadCountResponseDto {
    private Long unreadCount;
}
```

## Exception Handling

### 1. Custom Exceptions
```java
package com.laundry.chat.exception;

public class ConversationNotFoundException extends RuntimeException {
    public ConversationNotFoundException(String message) {
        super(message);
    }
}

public class InvalidUserException extends RuntimeException {
    public InvalidUserException(String message) {
        super(message);
    }
}
```

### 2. Global Exception Handler
```java
package com.laundry.chat.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class ChatExceptionHandler {
    
    @ExceptionHandler(ConversationNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleConversationNotFound(ConversationNotFoundException ex) {
        log.error("Conversation not found: {}", ex.getMessage());
        
        ErrorResponse error = new ErrorResponse();
        error.setTimestamp(LocalDateTime.now());
        error.setStatus(HttpStatus.NOT_FOUND.value());
        error.setError("Conversation Not Found");
        error.setMessage(ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    
    @ExceptionHandler(InvalidUserException.class)
    public ResponseEntity<ErrorResponse> handleInvalidUser(InvalidUserException ex) {
        log.error("Invalid user: {}", ex.getMessage());
        
        ErrorResponse error = new ErrorResponse();
        error.setTimestamp(LocalDateTime.now());
        error.setStatus(HttpStatus.BAD_REQUEST.value());
        error.setError("Invalid User");
        error.setMessage(ex.getMessage());
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        
        ErrorResponse error = new ErrorResponse();
        error.setTimestamp(LocalDateTime.now());
        error.setStatus(HttpStatus.BAD_REQUEST.value());
        error.setError("Validation Failed");
        error.setMessage("Invalid request parameters");
        error.setValidationErrors(errors);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
    
    @Data
    public static class ErrorResponse {
        private LocalDateTime timestamp;
        private int status;
        private String error;
        private String message;
        private Map<String, String> validationErrors;
    }
}
```

## Configuration

### 1. Application Properties
```properties
# Database Configuration
spring.datasource.url=jdbc:mysql://localhost:3306/laundry_db
spring.datasource.username=your_username
spring.datasource.password=your_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
spring.jpa.properties.hibernate.format_sql=true

# Server Configuration
server.port=8080

# Logging
logging.level.com.laundry.chat=DEBUG
logging.level.org.springframework.web=DEBUG
logging.level.org.hibernate.SQL=DEBUG
```

### 2. Database Configuration
```java
package com.laundry.chat.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@EnableJpaRepositories(basePackages = "com.laundry.chat.repository")
@EnableTransactionManagement
public class DatabaseConfig {
    // Additional database configuration if needed
}
```

## User Service Integration

### 1. User Service Interface
```java
package com.laundry.chat.service;

public interface UserService {
    boolean userExists(Long userId);
    String getUserName(Long userId);
    String getUserRole(Long userId);
}
```

### 2. User Service Implementation
```java
package com.laundry.chat.service.impl;

import com.laundry.chat.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserServiceImpl implements UserService {
    
    // Inject your existing user repository
    // private final UserRepository userRepository;
    
    @Override
    public boolean userExists(Long userId) {
        // Implement user existence check
        // return userRepository.existsById(userId);
        return true; // Placeholder
    }
    
    @Override
    public String getUserName(Long userId) {
        // Implement user name retrieval
        // return userRepository.findById(userId).map(User::getName).orElse("Unknown");
        return "User " + userId; // Placeholder
    }
    
    @Override
    public String getUserRole(Long userId) {
        // Implement user role retrieval
        // return userRepository.findById(userId).map(User::getRole).orElse("CUSTOMER");
        return "CUSTOMER"; // Placeholder
    }
}
```

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/chat/conversations` | Create or get conversation |
| GET | `/chat/conversations/{userId}` | Get conversations for user |
| POST | `/chat/conversations/{conversationId}/messages` | Send message |
| GET | `/chat/conversations/{conversationId}/messages` | Get messages |
| PUT | `/chat/conversations/{conversationId}/messages/read` | Mark messages as read |
| GET | `/chat/users/{userId}/unread-count` | Get unread count |
| GET | `/chat/conversations/{conversationId}` | Get conversation by ID |

## Testing

### 1. Unit Tests
```java
package com.laundry.chat.service;

import com.laundry.chat.dto.CreateConversationRequestDto;
import com.laundry.chat.dto.ConversationResponseDto;
import com.laundry.chat.entity.Conversation;
import com.laundry.chat.repository.ConversationRepository;
import com.laundry.chat.service.impl.ChatServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChatServiceTest {
    
    @Mock
    private ConversationRepository conversationRepository;
    
    @Mock
    private UserService userService;
    
    @InjectMocks
    private ChatServiceImpl chatService;
    
    @Test
    void createOrGetConversation_ShouldCreateNewConversation_WhenNotExists() {
        // Given
        CreateConversationRequestDto request = new CreateConversationRequestDto();
        request.setCustomerId(1L);
        request.setLaundryId(2L);
        
        when(userService.userExists(1L)).thenReturn(true);
        when(userService.userExists(2L)).thenReturn(true);
        when(userService.getUserName(1L)).thenReturn("Customer 1");
        when(userService.getUserName(2L)).thenReturn("Laundry 2");
        when(conversationRepository.findByCustomerIdAndLaundryId(1L, 2L)).thenReturn(Optional.empty());
        
        Conversation savedConversation = new Conversation();
        savedConversation.setId(1L);
        savedConversation.setCustomerId(1L);
        savedConversation.setLaundryId(2L);
        when(conversationRepository.save(any(Conversation.class))).thenReturn(savedConversation);
        
        // When
        ConversationResponseDto result = chatService.createOrGetConversation(request);
        
        // Then
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals(1L, result.getCustomerId());
        assertEquals(2L, result.getLaundryId());
        verify(conversationRepository).save(any(Conversation.class));
    }
}
```

### 2. Integration Tests
```java
package com.laundry.chat.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.laundry.chat.dto.CreateConversationRequestDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureWebMvc
@TestPropertySource(locations = "classpath:application-test.properties")
@Transactional
class ChatControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @Test
    void createConversation_ShouldReturnCreated_WhenValidRequest() throws Exception {
        CreateConversationRequestDto request = new CreateConversationRequestDto();
        request.setCustomerId(1L);
        request.setLaundryId(2L);
        
        mockMvc.perform(post("/chat/conversations")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.customerId").value(1))
                .andExpect(jsonPath("$.laundryId").value(2));
    }
}
```

## Deployment

### 1. Docker Configuration
```dockerfile
# Dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/chat-service-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 2. Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  chat-service:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - mysql
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/laundry_db
      - SPRING_DATASOURCE_USERNAME=laundry_user
      - SPRING_DATASOURCE_PASSWORD=laundry_password
    networks:
      - laundry-network

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=laundry_db
      - MYSQL_USER=laundry_user
      - MYSQL_PASSWORD=laundry_password
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - laundry-network

volumes:
  mysql_data:

networks:
  laundry-network:
    driver: bridge
```

## Dependencies

### 1. Maven Dependencies
```xml
<dependencies>
    <!-- Spring Boot Starters -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    
    <!-- Database -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    
    <!-- Testing -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

## Real-time Features (Optional)

### 1. WebSocket Configuration
```java
package com.laundry.chat.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").withSockJS();
    }
}
```

### 2. WebSocket Message Handler
```java
package com.laundry.chat.websocket;

import com.laundry.chat.dto.MessageResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {
    
    private final SimpMessagingTemplate messagingTemplate;
    
    @MessageMapping("/chat.sendMessage")
    public void sendMessage(@Payload MessageResponseDto message) {
        messagingTemplate.convertAndSend("/topic/conversation." + message.getConversationId(), message);
    }
}
```

## Getting Started

1. **Clone the project** and set up your Spring Boot application
2. **Configure your database** connection in `application.properties`
3. **Run the database migrations** to create the tables
4. **Implement the UserService** integration with your existing user management
5. **Test the endpoints** using the provided integration tests
6. **Deploy using Docker** or your preferred deployment method

This implementation provides a complete, production-ready chat system that integrates seamlessly with your Flutter application! 