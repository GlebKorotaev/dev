#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BINARY=$1
echo -e "${YELLOW}Running tests for Latin Square checker...${NC}\n"

TOTAL=0
PASSED=0
FAILED=0

run_test() {
    local test_name=$1
    local input=$2
    local expected_pattern=$3
    local description=$4
    
    TOTAL=$((TOTAL + 1))
    
    echo -e "${YELLOW}Test $TOTAL: $test_name${NC}"
    echo "Description: $description"
    echo "Input:"
    echo "$input"
    
    output=$(echo "$input" | $BINARY 2>&1 || true)
    
    echo "Output: $output"
    
    if echo "$output" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✓ PASSED${NC}\n"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Expected pattern: $expected_pattern"
        echo "Actual output: $output"
        echo ""
        FAILED=$((FAILED + 1))
    fi
}

# Тест 1: Корректный латинский квадрат 3x3
run_test \
    "Valid Latin Square 3x3" \
"3
1 2 3
2 3 1
3 1 2" \
    "является латинским квадратом" \
    "Проверка корректного латинского квадрата порядка 3"

# Тест 2: Корректный латинский квадрат 4x4
run_test \
    "Valid Latin Square 4x4" \
"4
1 2 3 4
2 1 4 3
3 4 1 2
4 3 2 1" \
    "является латинским квадратом" \
    "Проверка корректного латинского квадрата порядка 4"

# Тест 3: Повтор в строке
run_test \
    "Duplicate in row" \
"3
1 2 2
2 3 1
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка обнаружения повтора в строке (вторая строка содержит две 2)"

# Тест 4: Повтор в столбце
run_test \
    "Duplicate in column" \
"3
1 2 3
2 3 1
1 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка обнаружения повтора в столбце (первый столбец содержит две 1)"

# Тест 5: Неквадратная матрица (2x3)
run_test \
    "Non-square matrix" \
"2
1 2 3
4 5 6" \
    "НЕ является латинским квадратом" \
    "Проверка неквадратной матрицы (2 строки, 3 столбца)"

# Тест 6: Элементы вне диапазона (>n)
run_test \
    "Elements out of range (>n)" \
"3
1 2 4
2 3 1
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка элементов больше n (число 4 в позиции [1,3])"

# Тест 7: Элементы вне диапазона (<1)
run_test \
    "Elements out of range (<1)" \
"3
1 2 3
2 0 1
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка элементов меньше 1 (число 0 в позиции [2,2])"

# Тест 8: Латинский квадрат 1x1
run_test \
    "Valid Latin Square 1x1" \
"1
1" \
    "является латинским квадратом" \
    "Проверка тривиального случая - матрица 1x1"

# Тест 10: Матрица с отрицательными числами
run_test \
    "Matrix with negative numbers" \
"3
1 2 3
-1 3 1
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка наличия отрицательных чисел"

# Тест 12: Матрица с нулями
run_test \
    "Matrix with zeros" \
"3
1 2 3
0 3 1
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка наличия нулей (допустимы только числа от 1 до n)"

# Тест 13: Латинский квадрат с максимальным порядком
run_test \
    "Valid Latin Square 5x5" \
"5
1 2 3 4 5
2 3 4 5 1
3 4 5 1 2
4 5 1 2 3
5 1 2 3 4" \
    "является латинским квадратом" \
    "Проверка корректного латинского квадрата порядка 5"

# Тест 14: Матрица с одинаковыми строками
run_test \
    "Identical rows" \
"3
1 2 3
1 2 3
3 1 2" \
    "НЕ является латинским квадратом" \
    "Проверка матрицы с одинаковыми строками"

# Тест 15: Матрица с одинаковыми столбцами
run_test \
    "Identical columns" \
"3
1 2 3
2 3 1
1 2 3" \
    "НЕ является латинским квадратом" \
    "Проверка матрицы с одинаковыми столбцами (первый и третий столбцы)"

# Итоговый отчет
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi