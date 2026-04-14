// web/Taliesin.wasm
var Taliesin_default = "./Taliesin-11ervwr8.wasm";

// web/payload.js
var width = 1200;
var height = 600;
async function loadWasm() {
  const res = await fetch(Taliesin_default);
  const { instance, module } = await WebAssembly.instantiateStreaming(res);
  const exports = instance.exports;
  return exports;
}
window.addEventListener("load", async () => {
  const element = document.getElementById("app");
  if (!element || !(element instanceof HTMLCanvasElement)) {
    throw new Error("Canvas element not found");
  }
  const canvas = element;
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("Can't get context");
  }
  const exportsinstance = await loadWasm();
  const buffer_ptr = exportsinstance.alloc_buffer(width * height * 4);
  const array = new BigUint64Array(1);
  window.crypto.getRandomValues(array);
  const app = exportsinstance.app_init(buffer_ptr, width, height, array[0]);
  const buffer = new Uint8ClampedArray(exportsinstance.memory.buffer, buffer_ptr, width * height * 4);
  let last = 0;
  const upate = (now) => {
    const dt = (now - last) / 1000;
    last = now;
    exportsinstance.app_update(app, dt);
    const iamge = new ImageData(buffer, width, height);
    ctx.putImageData(iamge, 0, 0);
    requestAnimationFrame(upate);
  };
  requestAnimationFrame(upate);
});
