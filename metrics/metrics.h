#ifndef METRICS_H
#define METRICS_H

#ifdef __cplusplus
extern "C" {
#endif

// Инициализация метрик
void metrics_init(int port);

// Обновление метрик при проверке
void metrics_request_processed(int is_valid, double processing_time);

// Запуск HTTP сервера для метрик
void* metrics_server_thread(void* arg);

// Получение значения метрик (для отладки)
void metrics_print_all(void);

#ifdef __cplusplus
}
#endif

#endif // METRICS_H