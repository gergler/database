#include <iostream>
#include <mutex>
#include <thread>

std::mutex m1;
std::mutex m2;

void Lock1() {
    m1.lock();
    //std::this_thread::sleep_for(std::chrono::milliseconds(1));
    m2.lock();
    std::cout << "LOCK1" << std::endl;

    m1.unlock();
    m2.unlock();
}

void Lock2() {
    m2.lock();
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    m1.lock();
    std::cout << "LOCK2" << std::endl;

    m2.unlock();
    m1.unlock();
}

int main() {
    std::thread t1(Lock1);
    std::thread t2(Lock2);

    t1.join();
    t2.join();
    return 0;
}

//the argument which be have missed while generating object file in G++ compiler
//g++ -pthread main.cpp -o main
//./main
