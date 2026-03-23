#include "metrics.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <time.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// Структура для хранения метрик
typedef struct {
    long long total_requests;
    long long valid_requests;
    long long invalid_requests;
    double total_processing_time;
    double max_processing_time;
    double min_processing_time;
} metrics_data_t;

static metrics_data_t metrics = {0};
static pthread_mutex_t metrics_mutex = PTHREAD_MUTEX_INITIALIZER;
static int metrics_port = 9090;
static int server_running = 0;

void metrics_init(int port) {
    metrics_port = port;
    metrics.min_processing_time = 999999.0;
    printf("Metrics initialized on port %d\n", port);
}

void metrics_request_processed(int is_valid, double processing_time) {
    pthread_mutex_lock(&metrics_mutex);
    
    metrics.total_requests++;
    metrics.total_processing_time += processing_time;
    
    if (processing_time > metrics.max_processing_time) {
        metrics.max_processing_time = processing_time;
    }
    if (processing_time < metrics.min_processing_time) {
        metrics.min_processing_time = processing_time;
    }
    
    if (is_valid) {
        metrics.valid_requests++;
    } else {
        metrics.invalid_requests++;
    }
    
    pthread_mutex_unlock(&metrics_mutex);
}

void metrics_print_all(void) {
    pthread_mutex_lock(&metrics_mutex);
    
    printf("\n=== Metrics ===\n");
    printf("Total requests: %lld\n", metrics.total_requests);
    printf("Valid requests: %lld\n", metrics.valid_requests);
    printf("Invalid requests: %lld\n", metrics.invalid_requests);
    printf("Avg processing time: %.6f ms\n", 
           metrics.total_requests > 0 ? 
           (metrics.total_processing_time / metrics.total_requests) * 1000 : 0);
    printf("Min processing time: %.6f ms\n", metrics.min_processing_time * 1000);
    printf("Max processing time: %.6f ms\n", metrics.max_processing_time * 1000);
    
    pthread_mutex_unlock(&metrics_mutex);
}

// Простой HTTP сервер для отдачи метрик в формате Prometheus
static void handle_metrics_request(int client_fd) {
    char buffer[4096];
    
    pthread_mutex_lock(&metrics_mutex);
    
    // Формируем ответ в формате Prometheus
    snprintf(buffer, sizeof(buffer),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4\r\n"
        "Content-Length: %d\r\n"
        "\r\n"
        "# HELP latin_square_requests_total Total number of requests\n"
        "# TYPE latin_square_requests_total counter\n"
        "latin_square_requests_total %lld\n"
        "# HELP latin_square_valid_requests_total Number of valid Latin squares\n"
        "# TYPE latin_square_valid_requests_total counter\n"
        "latin_square_valid_requests_total %lld\n"
        "# HELP latin_square_invalid_requests_total Number of invalid Latin squares\n"
        "# TYPE latin_square_invalid_requests_total counter\n"
        "latin_square_invalid_requests_total %lld\n"
        "# HELP latin_square_avg_processing_time_ms Average processing time in milliseconds\n"
        "# TYPE latin_square_avg_processing_time_ms gauge\n"
        "latin_square_avg_processing_time_ms %.3f\n"
        "# HELP latin_square_min_processing_time_ms Minimum processing time in milliseconds\n"
        "# TYPE latin_square_min_processing_time_ms gauge\n"
        "latin_square_min_processing_time_ms %.3f\n"
        "# HELP latin_square_max_processing_time_ms Maximum processing time in milliseconds\n"
        "# TYPE latin_square_max_processing_time_ms gauge\n"
        "latin_square_max_processing_time_ms %.3f\n",
        0, // placeholder for content length
        metrics.total_requests,
        metrics.valid_requests,
        metrics.invalid_requests,
        metrics.total_requests > 0 ? (metrics.total_processing_time / metrics.total_requests) * 1000 : 0,
        metrics.min_processing_time * 1000,
        metrics.max_processing_time * 1000
    );
    
    // Пересчитываем длину
    int content_length = 0;
    char *ptr = buffer;
    while (*ptr) {
        if (*ptr == '\n' && ptr[1] == '\r') {
            content_length = 0;
            ptr += 2;
            while (*ptr) {
                content_length++;
                ptr++;
            }
            break;
        }
        ptr++;
    }
    
    // Исправляем заголовок с правильной длиной
    char response[8192];
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4\r\n"
        "Content-Length: %d\r\n"
        "\r\n"
        "# HELP latin_square_requests_total Total number of requests\n"
        "# TYPE latin_square_requests_total counter\n"
        "latin_square_requests_total %lld\n"
        "# HELP latin_square_valid_requests_total Number of valid Latin squares\n"
        "# TYPE latin_square_valid_requests_total counter\n"
        "latin_square_valid_requests_total %lld\n"
        "# HELP latin_square_invalid_requests_total Number of invalid Latin squares\n"
        "# TYPE latin_square_invalid_requests_total counter\n"
        "latin_square_invalid_requests_total %lld\n"
        "# HELP latin_square_avg_processing_time_ms Average processing time in milliseconds\n"
        "# TYPE latin_square_avg_processing_time_ms gauge\n"
        "latin_square_avg_processing_time_ms %.3f\n"
        "# HELP latin_square_min_processing_time_ms Minimum processing time in milliseconds\n"
        "# TYPE latin_square_min_processing_time_ms gauge\n"
        "latin_square_min_processing_time_ms %.3f\n"
        "# HELP latin_square_max_processing_time_ms Maximum processing time in milliseconds\n"
        "# TYPE latin_square_max_processing_time_ms gauge\n"
        "latin_square_max_processing_time_ms %.3f\n",
        content_length,
        metrics.total_requests,
        metrics.valid_requests,
        metrics.invalid_requests,
        metrics.total_requests > 0 ? (metrics.total_processing_time / metrics.total_requests) * 1000 : 0,
        metrics.min_processing_time * 1000,
        metrics.max_processing_time * 1000
    );
    
    pthread_mutex_unlock(&metrics_mutex);
    
    send(client_fd, response, strlen(response), 0);
    close(client_fd);
}

void* metrics_server_thread(void* arg) {
    int server_fd, client_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    
    // Создаем сокет
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        return NULL;
    }
    
    // Устанавливаем опции
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("setsockopt");
        close(server_fd);
        return NULL;
    }
    
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(metrics_port);
    
    // Привязываем сокет
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        close(server_fd);
        return NULL;
    }
    
    // Начинаем слушать
    if (listen(server_fd, 3) < 0) {
        perror("listen");
        close(server_fd);
        return NULL;
    }
    
    server_running = 1;
    printf("Metrics server listening on port %d\n", metrics_port);
    
    // Основной цикл сервера
    while (server_running) {
        if ((client_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            perror("accept");
            continue;
        }
        
        char buffer[1024] = {0};
        read(client_fd, buffer, 1024);
        
        // Проверяем запрос /metrics
        if (strstr(buffer, "GET /metrics") != NULL) {
            handle_metrics_request(client_fd);
        } else {
            // Отдаем 404 для других путей
            char *response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n";
            send(client_fd, response, strlen(response), 0);
            close(client_fd);
        }
    }
    
    close(server_fd);
    return NULL;
}