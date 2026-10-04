// rotating-cube - minimal Yume example.
//
// Shows the Caminho 1 project shape: the engine (yume_core) owns the window,
// renderer, scene loading and main loop via Yume::Application. This file only
// provides the project-specific bits by overriding the hooks:
//   - the initial scene comes from project.conf ("scene": "scene.scnb")
//   - onUpdate() spins the first mesh object in the scene every frame
//
// Build output and the compiled assets (scene.scnb, shaders, cube.obj,
// project.conf) all land next to this executable, which is also its working
// directory, so the engine resolves those relative paths directly.

#include "application.hpp"
#include "math/vector3.hpp"
#include "scene/scene.hpp"
#include "components/transform.hpp"
#include "scene/world_object_manager.hpp"

// Force the dedicated GPU on laptops with switchable graphics. These exported
// symbols are read by the NVIDIA/AMD drivers at process start. Windows-only.
#ifdef _WIN32
extern "C" {
__declspec(dllexport) unsigned long NvOptimusEnablement = 1;
__declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}
#endif

class RotatingCubeApp : public Yume::Application {
  protected:
    void onUpdate(float deltaTime) override {
        // Spin the first object that has a mesh. Matches the original demo:
        // 45 deg/s around X and Y.
        const float rotationSpeed = 45.0f; // degrees per second

        Scene* scene = scenes().getActiveScene();
        if (!scene)
            return;

        for (auto& obj : scene->getObjectManager()->getObjects()) {
            if (obj->hasMesh()) {
                Transform& transform = obj->getTransform();
                Vector3 rot = transform.getRotation();
                rot.x += rotationSpeed * deltaTime;
                rot.y += rotationSpeed * deltaTime;
                transform.setRotation(rot);
                break;
            }
        }
    }
};

int main() {
    RotatingCubeApp app;
    return app.run();
}
