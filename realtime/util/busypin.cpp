#include "busypin.h"
#include "constants.h"

#include <prussdrv.h>
#include <pruss_intc_mapping.h>

BusyPin::BusyPin()
{
    _pruDataMemory = nullptr;

    if (prussdrv_init() == -1)
        throw std::runtime_error("BusyPin - unable to init prussdrv");

    try
    {
        if (prussdrv_open(PRU_EVTOUT_0) == -1)
            throw std::runtime_error("BusyPin - unable to open a pruss event");

        tpruss_intc_initdata initData = PRUSS_INTC_INITDATA;

        if (prussdrv_pruintc_init(&initData) == -1)
            throw std::runtime_error("BusyPin - unable to init the pruss interrupt controller");

        if (prussdrv_map_prumem(PRUSS0_PRU0_DATARAM, reinterpret_cast<void**>(&_pruDataMemory)) == -1)
            throw std::runtime_error("BusyPin - unable to map the pru data memory");

        if (prussdrv_exec_program(kBusyPinPruNumber, kBusyPinPruBinary.c_str()) == -1)
            throw std::runtime_error("BusyPin - unable to execute a pru binary file");
    }
    catch (...)
    {
        prussdrv_exit();

        throw;
    }

    wait();
}

BusyPin::~BusyPin()
{
    cancel();

    prussdrv_pru_disable(kBusyPinPruNumber);
    prussdrv_exit();
}

bool BusyPin::wait()
{
    prussdrv_pru_wait_event(PRU_EVTOUT_0);

    uint32_t data = *_pruDataMemory;

    prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);

    return data & 0x0001 ? false : true; //if bit 0 is high, it is canceled
}

void BusyPin::cancel()
{
    prussdrv_pru_send_event(ARM_PRU0_INTERRUPT);
}
