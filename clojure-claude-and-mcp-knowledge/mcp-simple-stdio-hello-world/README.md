# Weather MCP Server

## Run

Run `./run.sh` or `clj -M:run`. It should do nothing but wait for a line of text and pressing ***enter***.

Entering

```
{"id":1,"method":"initialize","params":{}}
```

will yield

```
{"jsonrpc":"2.0","result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"weather-mcp","version":"1.0.0"}},"id":1}
```

Or do this here

```sh
$ echo '{"id":2,"method":"tools/list","params":{}}' | ./run.sh 
{"jsonrpc":"2.0","result":{"tools":[{"name":"get_current_weather","description":"Get current weather conditions for a specific location","inputSchema":{"type":"object","properties":{"latitude":{"type":"number","description":"Latitude coordinate"},"longitude":{"type":"number","description":"Longitude coordinate"}},"required":["latitude","longitude"]}}]},"id":2}
$ echo '{"id":3,"method":"tools/call","params":{"name":"get_current_weather","arguments":{"longitude":10,"latitude":20}}}' | ./run.sh
{"jsonrpc":"2.0","result":{"content":[{"type":"text","text":"{\"weather\":\"Current weather: Sunny and warm, 22°C with light winds from the southwest\",\"location\":{\"latitude\":20,\"longitude\":10}}"}]},"id":3}
```

## Adding MCP to Claude Code

Run

```sh
$ claude mcp add weather -- /absolute/path/to/run.sh
```
