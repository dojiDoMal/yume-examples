// rotating-cube - minimal Yume example.
//
// The engine (yume_core) owns the window, renderer, scene loading and main
// loop via Yume::Application. The initial scene comes from project.conf
// ("scene": "scene.scnb").
//
// The cube's spin is now driven by a YumeScript component instead of C++:
// scene.scn attaches { "type": "SCRIPT", "path": "rotate.ys" } to the cube, and
// rotate.ys rotates the object's transform every frame in its update(dt). So
// this file no longer needs to override onUpdate() at all -- the behavior lives
// in data/script.
//
// Build output and the compiled assets (scene.scnb, shaders, cube.obj,
// rotate.ys, project.conf) all land next to this executable, which is also its
// working directory, so the engine resolves those relative paths directly.

#include "application.hpp"

// Force the dedicated GPU on laptops with switchable graphics. These exported
// symbols are read by the NVIDIA/AMD drivers at process start. Windows-only.
#ifdef _WIN32
extern "C" {
__declspec(dllexport) unsigned long NvOptimusEnablement = 1;
__declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}
#endif

int main() {
  Yume::Application app;
  return app.run();
}
