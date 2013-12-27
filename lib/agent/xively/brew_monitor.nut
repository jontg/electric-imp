device.on("SendToXively", function(data) {
    tempChannel <- Xively.Channel("Temperature");
    tempChannel.Set(data.tempOutTwo);
    iceTempChannel <- Xively.Channel("IceChamberTemperature");
    iceTempChannel.Set(data.tempOut);
    voltChannel <- Xively.Channel("Voltage");
    voltChannel.Set(data.volt);
    fanVoltChannel <- Xively.Channel("FanVoltage");
    fanVoltChannel.Set(data.fanVolt);
    
    feed <- Xively.Feed(Xively.FEED_ID, [tempChannel, iceTempChannel, voltChannel, fanVoltChannel]);
    Xively.Put(feed);
});
