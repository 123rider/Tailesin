#ifndef Tailsin_h
#define Tailsin_h

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdint.h>

    typedef struct App App;

#include <stdio.h>
#include <stdint.h>

    // Define a struct that matches your Zig Color.Pixel layout
    typedef struct
    {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } Pixel;

    // seed used for random generation
    App *app_init(uint8_t *buffer, double width, double height, uint64_t seed);
    int32_t app_update(App *app, double dt);
    int32_t app_on_mouse_click(App *app, double x, double y);
    void app_deinit(App *app);
    uint8_t *alloc_buffer(size_t len);

#ifdef __cplusplus
}
#endif

#endif