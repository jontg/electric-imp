/*=------------------------------------------------= CONFIGURE =--=*/
 
on_off_pin <- hardware.pin8;
on_off_pin.configure(DIGITAL_OUT);
on_off_pin.write(1);

temp_pin <- hardware.pin9;
temp_pin.configure(ANALOG_IN);
 
// turn on WiFi power save to reduce power consumption when awake
imp.setpowersave(true);

const b_therm = 3988;
const t0_therm = 298.15;

/*=--------------------------------------------------= MEASURE =--=*/
function main() {

    // turn on the thermistor network
    on_off_pin.write(0);

    local v_high  = 0;
    local val = 0;

    // gather several ADC readings and average them (just takes out some noise)
    for(local i = 0; i < 10; i++){
        imp.sleep(0.01);
        v_high += hardware.voltage();
        val += temp_pin.read();
    }

    v_high = v_high / 10.0;
    val = val/10;

    // turn the thermistor network back off
    on_off_pin.write(1);

/*=--------------------------------------------------= CONVERT =--=*/

    // scale the ADC reading to a voltage by dividing by the full-scale value and multiplying by the supply voltage
    local v_therm = v_high * val / 65535.0;

    // calculate the resistance of the thermistor at the current temperature
    local r_therm = 10000.0 / ( (v_high / v_therm) - 1);

    local ln_therm = math.log(10000.0 / r_therm);
    local t_therm = (t0_therm * b_therm) / (b_therm - t0_therm * ln_therm) - 273.15;

    local f = (t_therm) * 9.0 / 5.0 + 32.0;

/*=--------------------------------------------------= RESPOND =--=*/

    server.log("Current temperature is " + format("%.01f", f));

    agent.send("SendToXively", {tempOut = f, volt = v_high});
}

/*=--------------------------------------------------= EXECUTE =--=*/

imp.onidle(function() {
    main();

    //Sleep for 15 minutes, minus the time past the 0:15 so we wake up near each 15 minute mark (prevents drifting on slow DHCP)
    server.sleepfor(900 - (time() % 900));
});
