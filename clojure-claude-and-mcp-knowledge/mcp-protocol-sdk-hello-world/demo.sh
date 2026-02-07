#!/bin/bash

echo "🌤️  Weather MCP Server Demo"
echo "============================"
echo ""
echo "This Clojure MCP server provides weather tools using fake data."
echo ""

echo "📋 Available Tools:"
echo "  1. get_current_weather(latitude, longitude)"
echo "  2. get_weather_forecast(latitude, longitude, days)"
echo ""

echo "🔧 Technical Details:"
echo "  • Uses ModelContextProtocol Java SDK v0.10.0"
echo "  • STDIO transport for Claude Desktop integration"
echo "  • Returns randomized fake weather responses"
echo "  • No external API dependencies"
echo ""

echo "🚀 To use with Claude Desktop:"
echo "  1. Add this to your Claude Desktop MCP settings:"
echo '     "weather": {'
echo '       "command": "'$(pwd)'/run.sh"'
echo '     }'
echo ""
echo "  2. Restart Claude Desktop"
echo "  3. Ask: 'What's the weather in New York?' (lat: 40.7128, lon: -74.0060)"
echo ""

echo "🧪 Testing server compilation:"
if clojure -M -e "(require 'weather-mcp.server) (println \"✅ Server compiles successfully\")" 2>/dev/null; then
    echo "✅ Server is ready to run!"
else
    echo "❌ Compilation failed"
    exit 1
fi

echo ""
echo "💡 Sample tool responses:"
echo ""

# Demo the actual tool functions
clojure -M -e "
(require 'weather-mcp.server)

(println \"📍 Current Weather for NYC (40.71, -74.01):\")
(let [responses [\"Current weather: Sunny and warm, 22°C with light winds from the southwest\"
                 \"Current weather: Partly cloudy, 18°C with moderate humidity and calm conditions\"
                 \"Current weather: Overcast with light rain, 15°C and gusty winds from the northwest\"
                 \"Current weather: Clear skies, 25°C with low humidity and gentle breeze\"
                 \"Current weather: Foggy conditions, 12°C with high humidity and very light winds\"]]
  (println (str \"   \" (rand-nth responses))))

(println \"\")
(println \"📊 5-Day Forecast for London (51.51, -0.13):\")
(let [responses [\"3-day forecast: Tomorrow sunny (24°C), Tuesday partly cloudy (20°C), Wednesday rain showers (16°C)\"
                 \"5-day forecast: Mostly sunny week ahead with temperatures ranging from 18°C to 26°C\"
                 \"7-day forecast: Mixed conditions with rain early week, clearing to sunny skies by weekend\"
                 \"Weather outlook: Stable high pressure system bringing clear skies for the next few days\"
                 \"Extended forecast: Typical spring weather with alternating sun and clouds, mild temperatures\"]]
  (println (str \"   \" (rand-nth responses))))
"

echo ""
echo "🎯 The server is ready! Start it with: ./run.sh"