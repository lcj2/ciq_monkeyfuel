//! =====================================================================
//! Project   : MonkeyFuel
//! File      : MonkeyFuelView.mc
//! Author    : lcj2
//!
//! Copyright (c) 2017, lcj2.
//! All rights reserved.
//!
//! Redistribution and use in source and binary forms, with or without
//! modification, are permitted provided that the following conditions
//! are met:
//!
//!     * Redistributions of source code must retain the above copyright
//!       notice, this list of conditions and the following disclaimer.
//!     * Redistributions in binary form must reproduce the above
//!       copyright notice, this list of conditions and the following
//!       disclaimer in the documentation and/or other materials
//!       provided with the distribution.
//!     * Neither the name of the author nor the names of its
//!       contributors may be used to endorse or promote products
//!       derived from this software without specific prior written
//!       permission.
//!
//! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//! "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//! LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//! FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//! COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//! INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//! BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//! CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//! LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//! ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//! POSSIBILITY OF SUCH DAMAGE.
//! =====================================================================

using Toybox.Application as App;
using Toybox.FitContributor as Fit;
using Toybox.WatchUi as Ui;

class MonkeyFuelView extends Ui.SimpleDataField {

    // ENUM of timer states
    enum
    {
        STOPPED,
        PAUSED,
        RUNNING
    }

    // ENUM of display selection
    enum
    {
        DISP_FUEL_CURRENT,
        DISP_FUEL_LAP,
        DISP_BURNRATE_CURRENT,
        DISP_BURNRATE_AVERAGE,
        DISP_BURNRATE_LAP
    }

    // calorie values
    hidden var _mCalorieValues = [ [105.0, Ui.loadResource(Rez.Strings.FuelType_Banana_Units)],
                                   [207.0, Ui.loadResource(Rez.Strings.FuelType_MonkeyFist_Units)] ];

    // FIT fields
    hidden var _mFITFuelRecord;
    hidden var _mFITFuelLap;
    hidden var _mFITFuelSession;
    hidden var _mFITBurnRateRecord;
    hidden var _mFITBurnRateLap;
    hidden var _mFITBurnRateSession;

    // user settings/properties
    hidden var _mPropFuelDisplay;
    hidden var _mPropFuelType;

    // instance variables
    hidden var _mTimerState = STOPPED;
    hidden var _mCalories = 0;
    hidden var _mCaloriesLastLap = 0;
    hidden var _mBurnRate = 0;
    hidden var _mBurnRateAvg = [0,0];
    hidden var _mBurnRateLapAvg = [0,0];

    //! Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = Ui.loadResource(Rez.Strings.FieldTitle);
        self.updateUserSettings();

        _mFITFuelRecord = self.createField(Ui.loadResource(Rez.Strings.FieldCurrent), 0, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_RECORD, :units => _mCalorieValues[_mPropFuelType][1] });
        _mFITFuelLap = self.createField(Ui.loadResource(Rez.Strings.FieldCurrent), 1, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_LAP, :units => _mCalorieValues[_mPropFuelType][1] });
        _mFITFuelSession = self.createField(Ui.loadResource(Rez.Strings.FieldCurrent), 2, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_SESSION, :units => _mCalorieValues[_mPropFuelType][1] });
        _mFITBurnRateRecord = self.createField(Ui.loadResource(Rez.Strings.FieldBurnRate), 3, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_RECORD, :units => _mCalorieValues[_mPropFuelType][1] + "/hr" });
        _mFITBurnRateLap = self.createField(Ui.loadResource(Rez.Strings.FieldBurnAverage), 4, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_LAP, :units => _mCalorieValues[_mPropFuelType][1] + "/hr" });
        _mFITBurnRateSession = self.createField(Ui.loadResource(Rez.Strings.FieldBurnAverage), 5, Fit.DATA_TYPE_FLOAT,
            { :mesgType => Fit.MESG_TYPE_SESSION, :units => _mCalorieValues[_mPropFuelType][1] + "/hr" });
    }

    //! Update user settings
    function updateUserSettings() {
        var app = App.getApp();
        _mPropFuelDisplay = (app.getProperty("PROP_FUEL_DISPLAY") == null) ? 0 : app.getProperty("PROP_FUEL_DISPLAY").toNumber();
        _mPropFuelType = (app.getProperty("PROP_FUEL_TYPE") == null) ? 0 : app.getProperty("PROP_FUEL_TYPE").toNumber();
    }

    //! This is called each time a lap is created, so increment the lap number.
    function onTimerLap()
    {
        _mCaloriesLastLap = _mCalories;
        _mBurnRateLapAvg = [0,0];
    }

    //! The timer was started, so set the state to running.
    function onTimerStart()
    {
        _mTimerState = RUNNING;
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerStop()
    {
        _mTimerState = STOPPED;
    }

    //! The timer was started, so set the state to running.
    function onTimerPause()
    {
        _mTimerState = PAUSED;
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerResume()
    {
        _mTimerState = RUNNING;
    }

    //! The timer was reeset, so reset all our tracking variables
    function onTimerReset()
    {
        _mTimerState = STOPPED;
        _mCalories = 0;
        _mCaloriesLastLap = 0;
        _mBurnRate = 0;
        _mBurnRateAvg = [0,0];
        _mBurnRateLapAvg = [0,0];
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method.
    function compute(info) {
        // perform fuel calculations
        if (info.calories != null) {
            _mCalories = info.calories / _mCalorieValues[_mPropFuelType][0];
        }
        if (info.energyExpenditure != null) {
            _mBurnRate = (_mTimerState != RUNNING) ? 0 : (info.energyExpenditure * 60.0) / _mCalorieValues[_mPropFuelType][0];
            if (_mTimerState == RUNNING) {
                _mBurnRateAvg = self.cumulativeAvg(_mBurnRateAvg[0], _mBurnRateAvg[1], _mBurnRate);
                _mBurnRateLapAvg = self.cumulativeAvg(_mBurnRateLapAvg[0], _mBurnRateLapAvg[1], _mBurnRate);
            }
        }

        // save FIT data
        _mFITFuelRecord.setData(_mCalories);
        _mFITFuelLap.setData(_mCalories - _mCaloriesLastLap);
        _mFITFuelSession.setData(_mCalories);
        _mFITBurnRateRecord.setData(_mBurnRate);
        _mFITBurnRateLap.setData(_mBurnRateLapAvg[0]);
        _mFITBurnRateSession.setData(_mBurnRateAvg[0]);

        // return value to display
        if (_mPropFuelDisplay == DISP_FUEL_CURRENT) {
            return _mCalories;
        } else if (_mPropFuelDisplay == DISP_FUEL_LAP) {
            return (_mCalories - _mCaloriesLastLap);
        } else if (_mPropFuelDisplay == DISP_BURNRATE_CURRENT) {
            return _mBurnRate;
        } else if (_mPropFuelDisplay == DISP_BURNRATE_AVERAGE) {
            return _mBurnRateAvg[0];
        } else if (_mPropFuelDisplay == DISP_BURNRATE_LAP) {
            return _mBurnRateLapAvg[0];
        } else {
            return _mCalories;
        }
    }

    //! Cumulative Average
    function cumulativeAvg(c, k, x) {
        return ([(x + (k * c * 1.0)) / (k + 1.0), k + 1]);
    }
}
