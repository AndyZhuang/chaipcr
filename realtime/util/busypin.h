#ifndef BUSYPIN_H
#define BUSYPIN_H

#include "instance.h"

class BusyPin
{
public:
    BusyPin();
    ~BusyPin();

    bool wait();
    void cancel();

private:
    uint32_t *_pruDataMemory;
};

class BusyPinInstance : public Instance<BusyPin> {};

#endif // BUSYPIN_H
