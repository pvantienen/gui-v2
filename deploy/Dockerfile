# Serve WASM build output on Render (or any Docker host).
# Populate deploy/wasm/ with the contents of build-wasm_files_to_copy/wasm/
# (from GitHub Actions artifact "venus-webassembly" → wasm/ folder).
FROM nginx:1.27-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/wasm/ /usr/share/nginx/html/
