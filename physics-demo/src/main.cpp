// physics-demo - exemplo mínimo de física da Yume Engine.
//
// A engine (yume_core) é dona da janela, do renderer, do carregamento de cena e
// do laço principal via Yume::Application. A cena inicial vem do project.conf
// ("scene": "scene.scnb").
//
// A cena (scene.scn) tem um cubo suspenso com um Rigidbody + BoxCollider e um
// piso com um PlaneCollider. Ao rodar, o PhysicsWorld da engine aplica gravidade
// ao cubo e resolve a colisão contra o plano — o cubo cai e para sobre o chão,
// quicando levemente (restitution 0.3). Nada disso precisa de código C++ aqui: o
// comportamento está nos dados/componentes.
//
// A simulação de física começa habilitada no boot (a engine ainda não tem um
// botão "play" de editor). Um editor futuro chamaria physics().setEnabled(false)
// em onInit para segurar a cena até o usuário dar play.

#include "application.hpp"

// Força a GPU dedicada em laptops com gráficos alternáveis. Esses símbolos
// exportados são lidos pelos drivers NVIDIA/AMD no início do processo. Só Windows.
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
