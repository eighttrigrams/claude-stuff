---
name: develop-tracker-ui
description: To develop the user interface of the application, you need to know how to start, stop, restart the app and where to find it.
---

Start the application with `make start`. Stop it with `make stop`.
Doing so starts and stops both the frontend and the backend.

The app will state the port its running on at startup like this: "Starting server on port <PORT>".

Logs are under `logs/tracker.log`.

Check `config.edn` for actual configuration, when there is need.

Testing is done with `make test` and `make e2e`.
