/*=------------------------------------------------= CONSTANTS =--=*/

// all calculations are done in Kelvin
// these are constants for this particular thermistor; if using a different one,
// check your datasheet
const b_therm = 3988;
const t0_therm = 298.15;

const RPM_DURATION = 3.0;
const MEASUREMENT_FREQUENCY = 10; // seconds

/*=-------------------------------------------= CONFIGURE PINS =--=*/

fan_relay1 <- hardware.pin2;
fan_relay1.configure(DIGITAL_OUT);
fan_relay1.write(1);

fan_relay2 <- hardware.pin5;
fan_relay2.configure(DIGITAL_OUT);
fan_relay2.write(1);

temp_subsystem <- hardware.pin8;
temp_subsystem.configure(DIGITAL_OUT);
temp_subsystem.write(1); 

brew_temp_pin <- hardware.pin9;
brew_temp_pin.configure(ANALOG_IN);

ice_temp_pin <- hardware.pin7;
ice_temp_pin.configure(ANALOG_IN);

fan_speed <- hardware.pin1;
fan_speed.configure(PULSE_COUNTER, RPM_DURATION, 2);

function setFanState(active) {
    if (active) {
        fan_relay1.write(0);
        fan_relay2.write(0);
    } else {
        fan_relay1.write(1);
        fan_relay2.write(1);
    }
}

/*=--------------------------------------------------= MEASURE =--=*/
function main() {

    local v_high  = 0;
    local brew_measurement = 0;
    local ice_measurement = 0;
    local fan_measurement = 0;

    fan_measurement = fan_speed.read();

    temp_subsystem.write(0);

    for (local i = 0; i < 10; i++) {
        imp.sleep(0.01);
        v_high += hardware.voltage();
        brew_measurement += brew_temp_pin.read();
        ice_measurement += ice_temp_pin.read();
    }

    v_high = v_high / 10.0;
    brew_measurement = brew_measurement/10;
    ice_measurement = ice_measurement/10;

    temp_subsystem.write(1);

/*=--------------------------------------------------= CONVERT =--=*/

    local fan_rpm = fan_measurement * 60.0 / RPM_DURATION;

    // scale the ADC reading to a voltage by dividing by the full-scale value and multiplying by the supply voltage
    local v_brew = v_high * brew_measurement / 65535.0;
    local v_ice = v_high * ice_measurement / 65535.0;

    // calculate the resistance of the thermistor at the current temperature
    local r_brew = 10000.0 / ( (v_high / v_brew) - 1);
    local r_ice = 10000.0 / ( (v_high / v_ice) - 1);

    local ln_brew = math.log(10000.0 / r_brew);
    local ln_ice = math.log(10000.0 / r_ice);

    local t_brew = (t0_therm * b_therm) / (b_therm - t0_therm * ln_brew) - 273.15;
    local t_ice = (t0_therm * b_therm) / (b_therm - t0_therm * ln_ice) - 273.15;

    local brew_temp = (t_brew) * 9.0 / 5.0 + 32.0;
    local ice_temp = (t_ice) * 9.0 / 5.0 + 32.0;

/*=--------------------------------------------------= RESPOND =--=*/

    local isActive = (ice_temp < 60.0 && brew_temp > 60.0);
    setFanState(isActive);

    server.log("Ice Room: " + format("%.01f", ice_temp) + ", Brew: " + format("%.01f", brew_temp) + ", Fan RPM: " + format("%.01f", fan_rpm) + ", " + (isActive ? "ACTIVATING" : "DISABLING") + " fans");
    agent.send("SendToXively", {ice_temp = ice_temp, brew_temp = brew_temp, volt = v_high, fan_rpm = fan_rpm});
}

/*=--------------------------------------------------= EXECUTE =--=*/

imp.onidle(function() {
    main();

    local time = time();
    time = time - time % MEASUREMENT_FREQUENCY + MEASUREMENT_FREQUENCY;

    local next_date = date(time);
    server.sleepuntil(next_date.hour, next_date.min, next_date.sec);
});
