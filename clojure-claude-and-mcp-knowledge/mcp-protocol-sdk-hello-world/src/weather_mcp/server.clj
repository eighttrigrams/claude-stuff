(ns weather-mcp.server
  (:require [clojure.data.json :as json])
  (:import [io.modelcontextprotocol.server.transport StdioServerTransportProvider]
           [io.modelcontextprotocol.server McpServer
            McpServerFeatures$AsyncToolSpecification]
           [io.modelcontextprotocol.spec McpSchema$ServerCapabilities
            McpSchema$Tool
            McpSchema$CallToolResult
            McpSchema$TextContent]
           [reactor.core.publisher Mono]
           [com.fasterxml.jackson.databind ObjectMapper])
  (:gen-class))

(def fake-current-weather-responses
  ["Current weather: Sunny and warm, 22°C with light winds from the southwest"
   "Current weather: Partly cloudy, 18°C with moderate humidity and calm conditions"
   "Current weather: Overcast with light rain, 15°C and gusty winds from the northwest"
   "Current weather: Clear skies, 25°C with low humidity and gentle breeze"
   "Current weather: Foggy conditions, 12°C with high humidity and very light winds"])

(defn- get-random-weather
  "Get a random fake weather response"
  [responses]
  (rand-nth responses))

(defn- create-async-tool
  "Creates an AsyncToolSpecification with the given parameters"
  [{:keys [name description schema tool-fn]}]
  (let [schema-json (json/write-str schema)]
    (McpServerFeatures$AsyncToolSpecification.
     (McpSchema$Tool. name description schema-json)
     (reify java.util.function.BiFunction
       (apply [_this _exchange arguments]
         (let [args-map (into {} (for [[k v] arguments] [(keyword k) v]))]
           (-> (Mono/fromCallable
                (fn []
                  (let [result (tool-fn args-map)]
                    (McpSchema$CallToolResult. 
                     [(McpSchema$TextContent. result)]
                     false))))
               (.onErrorReturn
                (McpSchema$CallToolResult. 
                 [(McpSchema$TextContent. "Error executing weather tool")]
                 true)))))))))

(defn- create-current-weather-tool
  "Create current weather tool specification"
  []
  (create-async-tool
   {:name "get_current_weather"
    :description "Get current weather conditions for a specific location"
    :schema {:type "object"
             :properties {:latitude {:type "number"
                                    :description "Latitude coordinate"}
                         :longitude {:type "number"
                                    :description "Longitude coordinate"}}
             :required ["latitude" "longitude"]}
    :tool-fn (fn [args-map]
               (let [latitude (:latitude args-map)
                     longitude (:longitude args-map)
                     weather (get-random-weather fake-current-weather-responses)]
                 (format "%s\nLocation: %.2f, %.2f" weather latitude longitude)))}))

(defn- create-mcp-server
  "Create MCP server with weather tools"
  []
  (try
    (let [transport-provider (StdioServerTransportProvider. (ObjectMapper.))
          server (-> (McpServer/async transport-provider)
                     (.serverInfo "weather-server" "1.0.0")
                     (.capabilities (-> (McpSchema$ServerCapabilities/builder)
                                        (.tools true)
                                        (.build)))
                     (.build))]
      
      ; Register tools
      (-> (.addTool server (create-current-weather-tool))
          (.subscribe))
      #_(-> (.addTool server (create-forecast-tool))
          (.subscribe))
      
      server)
    (catch Exception e
      (binding [*out* *err*]
        (println "Failed to initialize weather MCP server:" (.getMessage e)))
      (throw e))))

(defn -main
  "Main entry point for weather MCP server"
  [& _args]
  (try
    (let [_server (create-mcp-server)]
      ; Block the main thread to keep server running
      @(promise))
    (catch Exception e
      (binding [*out* *err*]
        (println "Failed to start weather MCP server:" (.getMessage e)))
      (System/exit 1))))