#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>

#define MAX_SIZE 100

bool isLatinSquare(int matrix[MAX_SIZE][MAX_SIZE], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (matrix[i][j] < 1 || matrix[i][j] > n) {
                return false;
            }
        }
    }

    for (int i = 0; i < n; i++) {
        bool seen[MAX_SIZE + 1] = { false };
        for (int j = 0; j < n; j++) {
            int val = matrix[i][j];
            if (seen[val]) {
                return false;
            }
            seen[val] = true;
        }
    }

    for (int j = 0; j < n; j++) {
        bool seen[MAX_SIZE + 1] = { false };
        for (int i = 0; i < n; i++) {
            int val = matrix[i][j];
            if (seen[val]) {
                return false;
            }
            seen[val] = true;
        }
    }

    return true;
}

void printMatrix(int matrix[MAX_SIZE][MAX_SIZE], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%d ", matrix[i][j]);
        }
        printf("\n");
    }
}

int main() {
    int n;
    int matrix[MAX_SIZE][MAX_SIZE];

    printf("Введите размер матрицы n: ");
    scanf("%d", &n);

    if (n <= 0 || n > MAX_SIZE) {
        printf("Ошибка: размер матрицы должен быть от 1 до %d\n", MAX_SIZE);
        return 1;
    }

    printf("Введите элементы матрицы %dx%d:\n", n, n);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            scanf("%d", &matrix[i][j]);
        }
    }

    printf("\nВведенная матрица:\n");
    printMatrix(matrix, n);

    if (isLatinSquare(matrix, n)) {
        printf("\nМатрица является латинским квадратом!\n");
    }
    else {
        printf("\nМатрица НЕ является латинским квадратом.\n");
    }

    return 0;
}