device.on("SendToXively", function(data) {
    tempChannel <- Xively.Channel("Temperature");
    tempChannel.Set(data.brew_temp);
    iceTempChannel <- Xively.Channel("IceChamberTemperature");
    iceTempChannel.Set(data.ice_temp);
    voltChannel <- Xively.Channel("Voltage");
    voltChannel.Set(data.volt);
    fanRPMChannel <- Xively.Channel("FanRPM");
    fanRPMChannel.Set(data.fan_rpm);
    
    feed <- Xively.Feed(Xively.FEED_ID, [tempChannel, iceTempChannel, voltChannel, fanRPMChannel]);
    Xively.Put(feed);
});
