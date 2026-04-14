import wasmUrl from "./Taliesin.wasm";


const width = 1200
const height = 600;

/**
 * @typedef {Object} TailsinExports
 * @property {function(number, number, number, bigint): number} app_init - (buffer*, w, h, seed) -> App*
 * @property {function(number, number): number} app_update - (App*, dt) -> int32
 * @property {function(number, number, number): number} app_on_mouse_click - (App*, x, y) -> int32
 * @property {function(number): void} app_deinit - (App*) -> void
 * @property {WebAssembly.Memory} memory
 * @property {function(number):number}alloc_buffer - (len)->uint8_t*;
 */
async function loadWasm() {
    const res = await fetch(wasmUrl);
    const { instance,module } = await WebAssembly.instantiateStreaming(res);

    /** @type {TailsinExports} */
    const exports = /** @type {any} */ (instance.exports);
    return exports;
}


window.addEventListener("load",(async()=>{
    const element = document.getElementById("app");

if (!element || !(element instanceof HTMLCanvasElement)) {
    throw new Error("Canvas element not found");
}

/** @type {HTMLCanvasElement} */
const canvas = element;
canvas.width = canvas.clientWidth;
canvas.height = canvas.clientHeight;
const ctx = canvas.getContext("2d");

if (!ctx) {
    throw new Error("Can't get context");
}

const exportsinstance = await loadWasm();
const buffer_ptr = exportsinstance.alloc_buffer(width*height*4)

const array = new BigUint64Array(1);
window.crypto.getRandomValues(array);

const app  =  exportsinstance.app_init(buffer_ptr,width,height,array[0])
const buffer = new Uint8ClampedArray(exportsinstance.memory.buffer, buffer_ptr, width*height*4);

let last = 0;

/** @param{number}now */ 
const upate = (now)=>{
    const dt = (now -last)/1000
    last = now;
    exportsinstance.app_update(app,dt);
    
    const iamge = new ImageData(buffer,width,height)
    ctx.putImageData(iamge,0,0)
    
    requestAnimationFrame(upate)
}

requestAnimationFrame(upate);

}))
