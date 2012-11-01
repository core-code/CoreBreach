#define FF_ALLOC_EVENT   (SDL_USEREVENT)
#define FF_REFRESH_EVENT (SDL_USEREVENT + 1)
#define FF_QUIT_EVENT (SDL_USEREVENT + 2)

#ifdef __cplusplus
extern "C" {
#endif
    
#include <SDL.h>

char startVideo(const char *filename, SDL_Surface *surface);
void stopVideo(void);
char isPlayingVideo();


void ff_alloc_handler(void *opaque);
void ff_refresh_handler(void *opaque);

    
#ifdef __cplusplus
}
#endif