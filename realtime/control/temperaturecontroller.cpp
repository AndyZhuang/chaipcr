//
// Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
// For more information visit http://www.chaibio.com
//
// Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include <sstream>
#include <cctype>

#include "exceptions.h"
#include "thermistor.h"
#include "pid.h"
#include "temperaturecontroller.h"
#include "logger.h"

TemperatureController::TemperatureController(Settings settings)
{
    _enableMode = false;

    _name = settings.name;
    _thermistor = settings.thermistor;
    _pidController = settings.pidController;
    _pidResult = 0;
    _minTargetTemp = settings.minTargetTemp;
    _maxTargetTemp = settings.maxTargetTemp;
    _minTempThreshold = settings.minTempThreshold;
    _maxTempThreshold = settings.maxTempThreshold;
    _targetTemperature = _minTargetTemp - 1;

    _thermistor->temperatureChanged.connect(boost::bind(&TemperatureController::computePid, this, _1));
}

TemperatureController::~TemperatureController()
{
    delete _pidController;
}

void TemperatureController::setEnableMode(bool enableMode)
{
    if (enableMode != _enableMode)
    {
        _enableMode = enableMode;

        if (_enableMode)
        {
            _pidController->reset();

            _pidMutex.lock();
            _pidState = true;
            _pidMutex.unlock();
        }
        else
        {
            _pidMutex.lock();
            _pidState = false;
            _pidMutex.unlock();

            resetOutput();
        }
    }
}

void TemperatureController::setTargetTemperature(double temperature)
{
    if (temperature < _minTargetTemp || temperature > _maxTargetTemp || std::isnan(temperature))
    {
        std::stringstream string;
        string << "Requested " << _name << " temperature (" << temperature << " C) outside limits of " << _minTargetTemp << '-' << _maxTargetTemp << " C";

        throw std::out_of_range(string.str());
    }

    _targetTemperature.store(temperature);
}

double TemperatureController::currentTemperature() const
{
    return _thermistor->temperature();
}

void TemperatureController::process()
{
    if (_enableMode)
    {
        processOutput();
    }
}

void TemperatureController::computePid(double currentTemperature)
{
    if (currentTemperature < _minTempThreshold)
    {
        std::string name = _name;
        name.at(0) = std::toupper(name.at(0));

        std::stringstream stream;
        stream << name << " temperature of " << currentTemperature << " C below limit of " << _minTempThreshold << " C";

        throw TemperatureLimitError(stream.str());
    }
    else if (currentTemperature > _maxTempThreshold)
    {
        std::string name = _name;
        name.at(0) = std::toupper(name.at(0));

        std::stringstream stream;
        stream << name << " temperature of " << currentTemperature << " C above limit of " << _maxTempThreshold << " C";

        throw TemperatureLimitError(stream.str());
    }
    else if (std::isnan(currentTemperature))
    {
        std::string name = _name;
        name.at(0) = std::toupper(name.at(0));

        std::stringstream stream;
        stream << name << " temperature is NaN";

        throw TemperatureLimitError(stream.str());
    }

    if (_targetTemperature < _minTargetTemp)
        _targetTemperature = currentTemperature;

    std::lock_guard<std::mutex> lock(_pidMutex);

    if (_pidState)
    {
        double result = _pidController->compute(targetTemperature(), currentTemperature);

        if (_enableMode && result != _pidResult)
        {
            _pidResult = result;
            setOutput(result);
        }
    }
}
