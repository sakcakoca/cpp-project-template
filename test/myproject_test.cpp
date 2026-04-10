#include <gtest/gtest.h>
#include <myproject/myproject.hpp>

TEST(MyProjectTest, AddReturnsSum) {
    EXPECT_EQ(myproject::add(2, 3), 5);
}

TEST(MyProjectTest, AddHandlesZero) {
    EXPECT_EQ(myproject::add(0, 0), 0);
}

TEST(MyProjectTest, AddHandlesNegative) {
    EXPECT_EQ(myproject::add(-1, 1), 0);
}
