doc:
    geng exec kast src/doc.ks

serve:
    geng transpile-to-c
    geng build-emscripten
    caddy file-server --root target/web --listen localhost:8080

publish:
    butler push target/web vesdev/bonk-to-the-future:html5

