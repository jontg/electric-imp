device.on("SendToXively", function(data) {
    tempChannel <- Xively.Channel("Temperature");
    tempChannel.Set(data.tempOut);
    voltChannel <- Xively.Channel("Voltage");
    voltChannel.Set(data.volt);
    
    feed <- Xively.Feed(Xively.FEED_ID, [tempChannel, voltChannel]);
    Xively.Put(feed);
});
