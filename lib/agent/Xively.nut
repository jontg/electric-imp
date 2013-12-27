// https://github.com/beardedinventor/electricimp
// This is a way to make a "namespace"
Xively <- {
    FEED_ID = "FEED_ID"     // Replace "FEED_ID" with the FeedID you are writing to
    API_KEY = "API_KEY"     // Replace "API_KEY" with the API Key you created
    triggers = []
}

/*****************************************
 * method: PUT
 * IN:
 *   feed: a XivelyFeed we are pushing to
 *   ApiKey: Your Xively API Key
 * OUT:
 *   HttpResponse object from Xively
 *   200 and no body is success
 *****************************************/
function Xively::Put(feed, ApiKey = Xively.API_KEY){
    if (ApiKey == null) ApiKey = Xively.API_KEY;
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
    local request = http.put(url, headers, feed.ToJson());

    return request.sendsync();
}
    
/*****************************************
 * method: GET
 * IN:
 *   feed: a XivelyFeed we fulling from
 *   ApiKey: Your Xively API Key
 * OUT:
 *   An updated XivelyFeed object on success
 *   null on failure
 *****************************************/
function Xively::Get(feed, ApiKey = Xively.API_KEY){
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
    local request = http.get(url, headers);
    local response = request.sendsync();
    if(response.statuscode != 200) {
        server.log("error sending message: " + response.body);
        return null;
    }
    
    local channel = http.jsondecode(response.body);
    for (local i = 0; i < channel.datastreams.len(); i++)
    {
        for (local j = 0; j < feed.Channels.len(); j++)
        {
            if (channel.datastreams[i].id == feed.Channels[j].id)
            {
                feed.Channels[j].current_value = channel.datastreams[i].current_value;
                break;
            }
        }
    }
    
    return feed;
}

class Xively.Feed{
    FeedID = null;
    Channels = null;
    
    constructor(feedID, channels)
    {
        this.FeedID = feedID;
        this.Channels = channels;
    }
    
    function GetFeedID() { return FeedID; }

    function ToJson()
    {
        local json = "{ \"datastreams\": [";
        for (local i = 0; i < this.Channels.len(); i++)
        {
            json += this.Channels[i].ToJson();
            if (i < this.Channels.len() - 1) json += ",";
        }
        json += "] }";
        return json;
    }
}
class Xively.Channel{
    id = null;
    current_value = null;
    
    constructor(_id)
    {
        this.id = _id;
    }
    
    function Set(value) { this.current_value = value; }
    
    function Get() { return this.current_value; }
    
    function ToJson() { return "{ \"id\" : \"" + this.id + "\", \"current_value\" : \"" + this.current_value + "\" }"; }    
}

device.on("XivelyFeed", function(data) {
    local channels = [];
    for(local i = 0; i < data.Datastreams.len(); i++)
    {
        local channel = Xively.Channel(data.Datastreams[i].id);
        channel.Set(data.Datastreams[i].current_value);
        channels.push(channel);
    }
    local feed = Xively.Feed(data.FeedID, channels);
    local resp = Xively.Put(feed, Xively.API_KEY);
    server.log("Send data to Xively (FeedID: " + feed.FeedID + ") - " + resp.statuscode + " " + resp.body);
});
function Xively::On(feedID, streamID, callback) {
    if (Xively.triggers == null) Xively.triggers = [];
    // Make sure the trigger doesn't already exist
    for(local i = 0; i < triggers.len(); i++) {
        if (Xively.triggers.FeedID == feedID && Xively.triggers.StreamID = streamID)
        {
            server.log("ERROR: A trigger already exists for " + feedID + " : " + streamID);
            return;
        }
    }
    Xively.triggers.push({ FeedID = feedID, StreamID = streamID, Callback = callback });
}
function Xively::HttpHandler(request,res) {
    local responseTable = http.urldecode(request.body);
    local parsedTable = http.jsondecode(responseTable.body);
    res.send(200, "okay");    
    
    local trigger = { 
        FeedID = parsedTable.environment.id,
        FeedName = parsedTable.environment.title,
        StreamID = parsedTable.triggering_datastream.id,
        ThresholdValue = parsedTable.threshold_value,
        CurrentValue = parsedTable.triggering_datastream.value.value,
        TriggeredAt = parsedTable.timestamp,
        Debug = false
    };
    if ("debug" in parsedTable) {
    	trigger.Debug = true;
        server.log(trigger.FeedID + "(" + trigger.StreamID + ") triggered at " + trigger.TriggeredAt + ": " + trigger.CurrentValue + " / " + trigger.ThresholdValue);
    }
    
    local callback = null;
    for (local i = 0; i < Xively.triggers.len(); i++)
    {
        if (Xively.triggers[i].FeedID = trigger.FeedID && Xively.triggers[i].StreamID == trigger.StreamID)
        {
            callback = Xively.triggers[i].Callback;
            break;
        }
    }
    if (callback == null){
        server.log("Unknown trigger from Xively - to create a callback for this trigger add the following line to your agent code:");
        server.log("Xively.On(\"" + trigger.FeedID + "\", \"" + trigger.StreamID + "\", triggerCallback);");
        return;
    }
    callback(trigger);
}
http.onrequest(function(req, resp) {
    if (req.path == "/xively") Xively.HttpHandler(req, resp);
});
/***************************************************** END OF API CODE *****************************************************/
