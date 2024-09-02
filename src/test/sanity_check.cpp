/**
 * @file sanity_check.cpp
 * @brief Sanity check test for CppUTest testing configuration.
 *
 * @author Jason Scott <reachme@jasonpscott.com>
 * @date 2024-09-02
 *
 * @copyright Copyright (c) 2024
 */
#include "CppUTest/TestHarness.h"

extern "C"
{
}

TEST_GROUP(SanityCheck){

    void setup(){}

    void teardown(){}

};

TEST(SanityCheck, returns_1)
{
    LONGS_EQUAL(1, 1);
}
