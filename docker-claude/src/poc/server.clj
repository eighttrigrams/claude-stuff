(ns poc.server
  (:import [com.sun.net.httpserver HttpServer HttpHandler]
           [java.net InetSocketAddress]))

(def page
  "<!doctype html>
<html><head><title>POC</title></head>
<body style=\"font-family:sans-serif;padding:2rem;background:#0b132b;color:#fff\">
  <h1 id=\"hello\">Hello from Headless Claude</h1>
  <p>Served by a Java HttpServer inside Docker.</p>
</body></html>")

(defn -main [& _]
  (let [port (Integer/parseInt (or (System/getenv "PORT") "8080"))
        server (HttpServer/create (InetSocketAddress. port) 0)]
    (.createContext server "/"
      (reify HttpHandler
        (handle [_ ex]
          (let [bytes (.getBytes page "UTF-8")]
            (.set (.getResponseHeaders ex) "Content-Type" "text/html; charset=utf-8")
            (.sendResponseHeaders ex 200 (count bytes))
            (with-open [os (.getResponseBody ex)]
              (.write os bytes))))))
    (.setExecutor server nil)
    (.start server)
    (println (str "Listening on http://0.0.0.0:" port))))
