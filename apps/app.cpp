#include <fmt/core.h>
#include <myproject/myproject.hpp>

int main() {
    fmt::println("2 + 3 = {}", myproject::add(2, 3));
    return 0;
}
