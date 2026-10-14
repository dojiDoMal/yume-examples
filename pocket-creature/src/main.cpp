// pocket-creature - exemplo da Yume engine: sprite animado por sprite sheet.
//
// A engine (yume_core) cuida de janela, renderer, carregamento da cena e loop
// principal via Yume::Application. A cena inicial vem de project.conf
// ("scene": "scene.scnb").
//
// Toda a lógica de animação vive no script anim.ys (anexado ao personagem em
// scene.scn): ele troca o frame/grupo do sprite conforme as setas, usando o
// suporte a sprite sheet (.ssm) adicionado à engine. Por isso este main não
// precisa sobrescrever onUpdate(): o comportamento está em dados/script.
//
// O executável e os assets compilados (scene.scnb, shaders, .ys, .png, .ssm,
// project.conf) ficam lado a lado neste diretório, que também é o working dir,
// então a engine resolve os caminhos relativos diretamente.

#include "application.hpp"

// Força a GPU dedicada em laptops com gráficos híbridos. Esses símbolos
// exportados são lidos pelos drivers NVIDIA/AMD no início do processo.
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
