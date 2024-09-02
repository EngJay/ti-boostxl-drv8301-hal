/**
 * @file all_tests.cpp
 * @brief Main entry point for running all of the CPpUTest tests.
 *
 * @author Jason Scott <reachme@jasonpscott.com>
 * @date 2024-09-02
 *
 * @copyright Copyright (c) 2024
 */
#include "CppUTest/CommandLineTestRunner.h"

int main(int ac, char **av)
{
    return CommandLineTestRunner::RunAllTests(ac, av);
}
