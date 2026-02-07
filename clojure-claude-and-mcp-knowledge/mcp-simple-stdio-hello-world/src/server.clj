(ns server
  (:require [cheshire.core :as json]))

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

(def tools-list 
  {:get-current-weather
   {:name "get_current_weather"
    :description "Get current weather conditions for a specific location"
    :inputSchema
    {:type "object"
     :properties
     {:latitude {:type "number"
                 :description "Latitude coordinate"}
      :longitude {:type "number" 
                  :description "Longitude coordinate"}}
     :required ["latitude" "longitude"]}}})

(defn get-current-weather [{:keys [latitude longitude] :as _arguments}]
  (let [weather (get-random-weather fake-current-weather-responses)]
    {:weather weather
     :location {:latitude latitude :longitude longitude}}))

(defn map-tool [name]
  (case name
    "get_current_weather" get-current-weather
    ;; Add more tools here
    nil))

(defn handle-request [request]
  (let [method (:method request)
        params (:params request)]
    (if (= method "notifications/initialized")
      nil
      (merge 
       {:jsonrpc "2.0"}
       (cond
         (= method "initialize")
         {:result {:protocolVersion "2024-11-05"
                   :capabilities    {:tools {}}  ;; Just declare "we have tools"
                   :serverInfo      {:name    "weather-mcp"
                                     :version "1.0.0"}}}
         (= method "tools/list")
         {:result  {:tools (mapv second tools-list)}}
         (= method "tools/call")
         (let [tool-name (get-in params [:name])
               arguments (get-in params [:arguments])
               f (map-tool tool-name)]
           (if f 
             (let [result (try (f arguments)
                               (catch IllegalArgumentException e
                                 {:error {:code    -32602
                                          :message (.getMessage e)}})
                               (catch UnsupportedOperationException e
                                 {:error {:code    -32801
                                          :message (.getMessage e)}}))]
               {:result  {:content [{:type "text"
                                     :text (json/generate-string result)}]}}) 
             {:error   {:code    -32601
                        :message "Unknown tool"}}))
         :else
         {:error   {:code    -32601
                    :message "Unknown method"}})))))

(defn process-line [line]
  (when-not (empty? line)
    (try
      (let [request (json/parse-string line true)
            response (handle-request request)]
        (when response  ; Only respond if there's a response (not for notifications)
          (let [response-with-id (assoc response :id (:id request))]
            (println (json/generate-string response-with-id))
            (flush))))
      (catch Exception _e
        (println (json/generate-string {:jsonrpc "2.0"
                                        :error {:code -32700
                                                :message "Parse error"}
                                        :id nil}))
        (flush)))))

(defn -main [& _args]
  (doseq [line (line-seq (java.io.BufferedReader. *in*))]
    (process-line line)))
