See Inventory/Server/README.md

Notes:
- bson package is locked to version 4 because bson@5 and @6 rely on top-level await, which is not available

Knowledge:
- useCallback is important if you are using functions as dependencies for useEffect; this is because
every time the component changes, a new function is created!
- StrictMode causes components to be mounted twice, so requests will be fired twice, and maybe same
for websockets