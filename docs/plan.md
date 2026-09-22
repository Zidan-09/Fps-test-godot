# Projeto: FPS 3D de estudo inspirado em Call of Duty Mobile

## Objetivo

Desenvolva um jogo FPS 3D completo e jogável utilizando **Godot Engine 4.x**, com foco em estudo e aprendizado da arquitetura da Godot, sistemas de gameplay, IA, animações, armas, movimentação, interface e organização de projetos.

O jogo deve ser **fortemente inspirado na experiência de um FPS multiplayer mobile/arcade moderno**, especialmente no ritmo e na movimentação de Call of Duty Mobile, porém deve utilizar **nomes, modelos, texturas, sons, personagens, armas, efeitos e demais assets originais ou livres de uso**.

Não copie assets proprietários de Call of Duty.

O projeto deve ser desenvolvido como um **protótipo single-player offline**, simulando uma partida de Deathmatch contra bots controlados por IA.

---

# 1\. Tecnologias

Utilize:

- Godot Engine 4.x
- GDScript
- Renderização 3D
- CharacterBody3D para jogador e personagens
- NavigationAgent3D para IA
- AnimationPlayer e/ou AnimationTree para animações
- RayCast3D para detecção de tiros/hitscan quando apropriado
- Resources personalizados para dados das armas
- Signals para comunicação entre sistemas
- UI construída com Control/CanvasLayer
- InputMap da Godot para todos os controles

Não utilize código excessivamente monolítico.

Organize o projeto em sistemas independentes e reutilizáveis.

---

# 2\. Objetivo do jogo

Criar um FPS 3D de partidas rápidas no modo:

**TEAM/FREE-FOR-ALL DEATHMATCH**

Para a primeira versão, implemente **Free For All Deathmatch**.

O jogador entra em uma pequena arena e enfrenta bots.

Cada eliminação aumenta o contador de kills do jogador.

A partida possui duração configurável.

Configuração padrão:

- Duração: 5 minutos
- Número de bots: 7
- Limite máximo de jogadores simultâneos: 8
- Vitória: jogador com maior número de kills ao final
- Se o tempo acabar, mostrar placar final
- Também permitir configurar um limite de kills, por exemplo 30 kills

Estruture o sistema para permitir posteriormente adicionar Team Deathmatch.

---

# 3\. Loop principal

O fluxo do jogo deve ser:

MENU PRINCIPAL\
 ↓\
 LOADOUT\
 ↓\
 INICIAR PARTIDA\
 ↓\
 SPAWN DO JOGADOR\
 ↓\
 SPAWN DOS BOTS\
 ↓\
 DEATHMATCH\
 ↓\
 MORTE\
 ↓\
 RESPAWN\
 ↓\
 CONTINUAÇÃO DA PARTIDA\
 ↓\
 TEMPO ACABA\
 ↓\
 PLACAR FINAL\
 ↓\
 OPÇÕES:

- Jogar novamente
- Voltar ao menu

Implemente transições apropriadas entre essas fases.

---

# 4\. FPS Player Controller

Crie um controlador FPS completo e responsivo.

O jogador deve conseguir:

- Andar para frente
- Andar para trás
- Andar lateralmente
- Correr
- Agachar
- Deslizar
- Pular
- Mirar
- Atirar
- Recarregar
- Trocar de arma
- Morrer
- Respawnar

O movimento deve ser arcade e responsivo.

Não criar um sistema excessivamente realista.

---

# 5\. Controles

Utilize teclado e mouse.

Configuração padrão:

- W = andar para frente
- S = andar para trás
- A = esquerda
- D = direita
- Shift = correr
- Ctrl = agachar
- Space = pular
- Mouse esquerdo = atirar
- Mouse direito = mirar
- R = recarregar
- 1 = arma primária
- 2 = pistola
- Mouse wheel = trocar arma
- Esc = menu/pausa

Todas as ações devem ser configuradas através do **InputMap da Godot**, não através de verificações espalhadas pelo código.

---

# 6\. Sistema de corrida

Implementar:

- Velocidade normal
- Velocidade de corrida
- FOV levemente aumentado durante corrida
- Animação de corrida
- Redução/alteração do movimento da arma durante corrida
- Não permitir mirar enquanto estiver correndo em velocidade máxima

Valores devem ser configuráveis.

Exemplo:

NORMAL_SPEED = 5.5\
 SPRINT_SPEED = 8.5

Não fixe valores diretamente em vários scripts.

Centralize configurações importantes.

---

# 7\. Sistema de slide

Implementar uma mecânica de slide inspirada em FPS arcade modernos.

O slide deve funcionar aproximadamente assim:

1. Jogador começa a correr.
2. Jogador pressiona o botão de agachar.
3. Se estiver com velocidade suficiente, inicia o slide.
4. Durante o slide:
   - corpo fica mais baixo
   - câmera diminui de altura
   - velocidade inicial é mantida
   - velocidade diminui gradualmente
5. Após o slide:
   - jogador volta para estado agachado ou normal dependendo do input.

Adicionar cooldown/configuração para evitar abuso da mecânica.

Criar uma pequena inclinação/balanço da câmera durante o slide.

---

# 8\. Sistema de pulo

Implementar:

- Pulo responsivo
- Gravidade
- Detecção de chão
- Pequeno coyote time opcional
- Controle de movimento no ar
- Animação adequada

Não permitir pulo infinito.

---

# 9\. Câmera FPS

Criar câmera em primeira pessoa.

Mouse controla:

- Rotação horizontal do jogador
- Rotação vertical da câmera

Adicionar:

- Sensibilidade configurável
- Clamp vertical
- FOV configurável
- Head bob opcional
- Camera shake ao disparar
- Camera shake ao receber dano
- Alteração de FOV durante sprint

Todos esses efeitos devem ser facilmente desativáveis.

---

# 10\. Sistema de vida

O jogador deve possuir:

- HP máximo: 100
- HP atual
- Dano recebido
- Morte
- Respawn

Implementar sistema de regeneração automática.

## Regeneração

Quando o jogador receber dano:

- interromper regeneração
- iniciar contador de recuperação

Se o jogador ficar sem receber dano durante aproximadamente 3 segundos:

- começar a regenerar HP automaticamente

Exemplo:

MAX_HEALTH = 100\
 REGEN_DELAY = 3.0\
 REGEN_RATE = 25 HP/s

Os valores devem ser configuráveis.

A regeneração deve parar novamente caso o jogador receba dano.

---

# 11\. Sistema de dano

Criar sistema genérico:

DamageInfo

que permita futuramente suportar:

- dano
- atacante
- arma
- parte atingida
- crítico/headshot
- distância
- multiplicador

O sistema deve permitir que armas diferentes causem danos diferentes.

---

# 12\. Sistema de armas

Implementar inicialmente 5 categorias:

1. Assault Rifle
2. Pistol
3. Sniper Rifle
4. Shotgun
5. SMG

Não utilizar nomes reais de armas da franquia Call of Duty.

Crie nomes originais.

Exemplo:

- AR-01 "Raptor"
- PX-9 "Viper"
- SR-01 "Sentinel"
- SG-12 "Hammer"
- SMG-07 "Wasp"

Os nomes podem ser alterados posteriormente.

---

# 13\. Arquitetura das armas

Não criar uma classe completamente diferente para cada arma.

Criar um sistema genérico de armas baseado em dados.

Exemplo:

Weapon\
 WeaponData\
 WeaponController

WeaponData deve conter:

- nome
- categoria
- dano
- dano mínimo
- cadência
- tamanho do carregador
- munição reserva
- tempo de recarga
- alcance
- precisão
- spread
- recoil
- multiplicador de headshot
- velocidade de movimento
- zoom/FOV ao mirar
- tipo de disparo
- quantidade de projéteis
- distância efetiva

Usar Resource da Godot para armazenar esses dados.

Exemplo conceitual:

WeaponData extends Resource

Assim será possível criar novas armas pelo editor sem modificar código.

---

# 14\. Assault Rifle

Criar uma arma equilibrada.

Características:

- Médio alcance
- Boa precisão
- Dano médio
- Cadência média/alta
- Carregador de aproximadamente 30 balas
- Recuo moderado

Suporte a:

- Hip fire
- ADS
- Recarregamento
- Recoil
- Muzzle flash
- Som de disparo
- Impacto de bala

---

# 15\. Pistola

Criar arma secundária.

Características:

- Dano médio
- Curto/médio alcance
- Carregador pequeno
- Alta mobilidade
- Boa velocidade de troca

---

# 16\. Sniper Rifle

Criar sniper.

Características:

- Alto dano
- Baixa cadência
- Longo alcance
- Alta precisão
- Zoom elevado
- Recuo forte
- Tempo de recarga maior

Um headshot deve normalmente resultar em eliminação contra inimigos com HP completo.

Implementar scope simples usando alteração do FOV.

Não é necessário criar um sistema de scope visual extremamente complexo na primeira versão.

---

# 17\. Shotgun

Criar shotgun.

Características:

- Curto alcance
- Alto dano próximo
- Vários pellets por disparo
- Spread
- Baixa cadência
- Carregamento/reload apropriado

O dano deve ser calculado individualmente para cada pellet.

---

# 18\. SMG

Criar SMG.

Características:

- Alta cadência
- Alto DPS em curta distância
- Baixo dano individual
- Maior mobilidade
- Spread maior
- Recuo moderado

---

# 19\. Sistema de tiro

Implementar dois tipos de disparo:

## Hitscan

Para:

- Assault Rifle
- Pistol
- SMG
- Sniper

Usar RayCast3D ou ray query da física.

## Shotgun

Disparar múltiplos rays/pellets em diferentes direções utilizando spread.

O sistema deve detectar:

- Corpo
- Cabeça
- Objetos do cenário

Implementar headshot.

Exemplo:

BODY_MULTIPLIER = 1.0\
 HEAD_MULTIPLIER = 2.0

---

# 20\. ADS / Mira

Ao pressionar botão direito:

- entrar em ADS
- reduzir FOV
- reduzir spread
- alterar posição da arma
- reduzir velocidade de movimento
- mostrar crosshair apropriado

Ao soltar:

- retornar ao hip fire

A transição deve ser suave utilizando Tween ou AnimationPlayer.

---

# 21\. Recoil

Implementar recoil visual e funcional.

Ao disparar:

- câmera sobe levemente
- arma movimenta
- spread aumenta dependendo da arma
- recoil retorna gradualmente

Cada arma deve possuir valores próprios.

Evitar recoil exagerado.

---

# 22\. Reload

Ao pressionar R:

- verificar se existe munição reserva
- executar animação
- remover munição do carregador
- adicionar munição ao carregador
- reduzir munição reserva

Durante reload:

- bloquear tiro
- tocar som
- tocar animação

Adicionar reload cancel quando apropriado, por exemplo ao disparar ou trocar de arma, mas não precisa ser extremamente complexo.

---

# 23\. Sistema de munição

Cada arma deve possuir:

- MagazineAmmo
- ReserveAmmo
- MagazineSize

Exemplo:

30 / 90

O HUD deve mostrar:

30\
 90

---

# 24\. Troca de armas

O jogador deve poder carregar:

- 1 arma primária
- 1 arma secundária

Exemplo:

Primary:\
 Raptor Assault Rifle

Secondary:\
 Viper Pistol

Implementar:

- troca instantânea ou rápida
- animação
- bloqueio durante reload
- som de troca

---

# 25\. Animações

Criar um sistema que suporte:

- Idle
- Walk
- Run
- Sprint
- Crouch
- Slide
- Jump
- Fall
- Shoot
- Reload
- ADS
- Death

Caso não existam modelos/animations externos disponíveis, criar uma implementação funcional utilizando animações simples/procedurais ou placeholders.

O jogo deve continuar totalmente jogável mesmo sem assets externos.

---

# 26\. Inimigos / Bots

O jogo deve possuir inimigos controlados por IA.

Criar uma classe:

EnemyCharacter

Cada bot deve possuir:

- HP
- arma
- visão
- movimento
- navegação
- ataque
- morte
- respawn
- pontuação

Utilizar:

NavigationRegion3D\
 NavigationAgent3D

---

# 27\. IA dos bots

Criar uma IA simples, mas funcional.

Estados:

IDLE\
 PATROL\
 SEARCH\
 CHASE\
 ATTACK\
 TAKE_COVER\
 DEAD

Fluxo básico:

Se não detectar inimigo:\
 → patrulhar/mover pelo mapa

Se detectar jogador:\
 → perseguir

Se estiver em alcance:\
 → atacar

Se perder jogador:\
 → procurar último local conhecido

Se morrer:\
 → entrar em DEAD

Após alguns segundos:\
 → respawn

Não é necessário criar uma IA extremamente avançada.

Priorizar comportamento convincente e código didático.

---

# 28\. Percepção dos bots

O bot deve conseguir detectar o jogador utilizando:

- Distância
- Campo de visão
- Raycast para verificar linha de visão

O bot não deve enxergar através de contêineres e paredes.

Criar parâmetros configuráveis:

VISION_DISTANCE\
 VISION_ANGLE\
 REACTION_TIME\
 AIM_ACCURACY

---

# 29\. Precisão dos bots

Não criar bots com precisão perfeita.

Cada dificuldade pode modificar:

- tempo de reação
- precisão
- distância de detecção
- agressividade
- tempo entre disparos

Criar pelo menos:

EASY\
 NORMAL\
 HARD

---

# 30\. Sistema de respawn

Quando o jogador morrer:

- mostrar indicação de morte
- bloquear controle
- aguardar aproximadamente 2 segundos
- escolher spawn válido
- restaurar HP
- restaurar arma
- reposicionar jogador
- retornar controle

Não spawnar diretamente na frente de um inimigo se for possível evitar.

Criar um sistema simples de escolha de spawn.

---

# 31\. Spawn points

Criar vários SpawnPoint3D no mapa.

Cada spawn deve possuir:

- posição
- rotação
- equipe futura opcional
- prioridade

Para Free For All, selecionar spawn com base em uma avaliação simples:

- distância dos inimigos
- linha de visão
- ocupação

Evitar spawns onde um inimigo está muito próximo.

---

# 32\. Mapa

Criar um mapa original inspirado na estrutura de Shipment.

IMPORTANTE:

Não copiar texturas, modelos ou assets de Call of Duty.

A inspiração deve estar apenas no conceito de arena compacta de contêineres.

O mapa deve ser:

- Pequeno
- Quadrado
- Simétrico ou aproximadamente simétrico
- Extremamente focado em combate próximo
- Com corredores estreitos
- Com contêineres
- Com área central
- Com áreas periféricas
- Com múltiplas linhas de visão
- Com cobertura

A referência pesquisada descreve Shipment como um mapa extremamente pequeno, com uma área central formada por conjuntos de contêineres e um perímetro com contêineres parcialmente abertos. A versão de Call of Duty: Mobile possui uma área central de cruzamento e um caminho periférico quadrado. Call of Duty+1

---

# 33\. Layout do mapa

Criar uma arena aproximadamente quadrada.

Dimensão sugerida:

aproximadamente 50m x 50m.

Não precisa ser uma reprodução dimensional exata.

Estrutura:

+--------------------------------+\
 | CONTAINERS SPAWN |\
 | |\
 | \[====\] \[====\] |\
 | \[====\] CENTER \[====\] |\
 | \[====\] |\
 | \[====\] |\
 | \[====\] \[====\] |\
 | |\
 | SPAWN |\
 +--------------------------------+

Criar quatro grandes conjuntos/pilares de contêineres em torno da região central, formando corredores e linhas de passagem.

O objetivo é produzir a sensação de:

- quatro blocos de contêineres
- centro extremamente perigoso
- corredores laterais
- rotas alternativas
- combate constante

---

# 34\. Contêineres

Criar modelos simples de contêineres utilizando meshes 3D simples.

Cada contêiner deve possuir:

- paredes
- portas
- interior quando necessário
- colisão
- material metálico
- cores variadas

Usar principalmente:

- vermelho
- azul
- verde
- amarelo
- cinza

Não utilizar logos reais.

Adicionar detalhes simples:

- ferrugem
- riscos
- sujeira
- pequenas diferenças de material

Pode utilizar materiais procedurais ou simples para evitar dependência de assets externos.

---

# 35\. Cobertura

Adicionar:

- caixas
- barris
- pallets
- pequenos obstáculos
- contêineres abertos
- contêineres parcialmente abertos
- veículos ou objetos genéricos

Todos devem ser assets originais/procedurais.

---

# 36\. Verticalidade

Adicionar uma pequena quantidade de verticalidade.

Permitir que algumas áreas tenham:

- caixas empilhadas
- plataformas
- pequenas posições elevadas

Mas não transformar o mapa em um mapa vertical.

A maior parte do combate deve ocorrer no chão.

---

# 37\. Lighting

Criar iluminação 3D adequada.

Utilizar:

- DirectionalLight3D
- WorldEnvironment
- Ambient lighting
- sombras
- iluminação de contêineres

Criar atmosfera de um pátio industrial.

Sugestão:

- céu nublado
- iluminação fria
- chão levemente molhado
- luzes industriais

Não exagerar no pós-processamento.

O desempenho deve ser prioridade.

---

# 38\. Performance

O jogo deve funcionar bem em computadores intermediários.

Priorizar:

- baixo número de draw calls
- meshes simples
- materiais simples
- colisões simples
- occlusion quando apropriado
- LOD quando necessário
- evitar scripts executando lógica pesada a cada frame
- evitar loops desnecessários

Não criar sistemas complexos sem necessidade.

---

# 39\. HUD

Criar HUD FPS.

Mostrar:

## Canto superior

Placar:

KILLS: 12\
 DEATHS: 7

## Centro superior

Timer:

04:32

## Canto inferior direito

Arma:

RAPTOR\
 30 / 90

## Centro

Crosshair.

## Vida

Mostrar barra/indicador de HP.

Quando receber dano:

- efeito visual discreto
- indicador direcional opcional

---

# 40\. Kill feed

Criar kill feed no canto superior direito.

Exemplo:

PLAYER → BOT_03

BOT_02 → BOT_07

PLAYER → BOT_05

Cada evento deve desaparecer depois de alguns segundos.

---

# 41\. Indicadores de hit

Ao acertar um inimigo:

- pequeno hitmarker

Ao acertar headshot:

- hitmarker diferente

Ao matar:

- confirmação visual

Exemplo:

HIT\
 HEADSHOT\
 ELIMINATION

---

# 42\. Sistema de pontuação

Cada kill:

+1 Kill

Cada morte:

+1 Death

Não contar suicídio como kill.

Ao final:

Ordenar jogadores por quantidade de kills apenas para apresentação do placar, sem aplicar nenhum sistema competitivo.

Mostrar:

RANK\
 PLAYER\
 KILLS\
 DEATHS

O jogador deve ser destacado no placar.

---

# 43\. Menu principal

Criar:

PLAY\
 LOADOUT\
 SETTINGS\
 QUIT

PLAY inicia a partida.

LOADOUT permite escolher arma.

SETTINGS permite configurar:

- Mouse sensitivity
- FOV
- Volume
- Master volume
- Effects volume
- Music volume
- Graphics quality

QUIT encerra o jogo.

---

# 44\. Tela de loadout

Criar uma tela simples onde o jogador pode escolher:

Primary:

- Assault Rifle
- SMG
- Shotgun
- Sniper

Secondary:

- Pistol

Mostrar:

- nome
- dano
- fire rate
- magazine
- alcance

Não precisa de sistema de progressão.

Todas as armas podem estar desbloqueadas.

---

# 45\. Tela de pausa

Ao pressionar ESC:

PAUSED

Opções:

- Resume
- Settings
- Restart Match
- Main Menu

Pausar corretamente:

- gameplay
- IA
- animações
- timers

---

# 46\. Game Manager

Criar um GameManager responsável por:

- estado da partida
- timer
- pontuação
- kills
- deaths
- vitória
- spawn
- respawn
- término da partida

Estados:

MENU\
 LOADING\
 PLAYING\
 PAUSED\
 MATCH_END

---

# 47\. Event Bus / Signals

Utilizar Signals da Godot para eventos como:

player_died\
 enemy_died\
 weapon_fired\
 weapon_reloaded\
 damage_received\
 kill_registered\
 match_started\
 match_ended\
 player_respawned

Evitar dependências excessivas entre scripts.

---

# 48\. Organização de pastas

Estruturar o projeto aproximadamente assim:

res://

```
scenes/
    main/
    player/
    enemies/
    weapons/
    map/
    ui/

scripts/
    core/
    player/
    enemies/
    weapons/
    gameplay/
    ui/

resources/
    weapons/
    characters/
    gameplay/

assets/
    models/
    textures/
    materials/
    audio/
    animations/

levels/

shaders/

data/
```

Não colocar todos os scripts na raiz.

---

# 49\. Cenas

Criar cenas separadas para:

Player.tscn\
 Enemy.tscn\
 Weapon.tscn\
 Map.tscn\
 MainMenu.tscn\
 HUD.tscn\
 PauseMenu.tscn\
 MatchEnd.tscn

Utilizar composição de cenas da Godot.

---

# 50\. Código

O código deve ser:

- limpo
- modular
- comentado quando necessário
- fácil de estudar
- fortemente tipado quando possível
- sem duplicação desnecessária
- sem valores mágicos espalhados
- organizado por responsabilidade

Evite:

- scripts gigantes
- singletons desnecessários
- código duplicado para cada arma
- lógica de UI misturada com lógica de gameplay
- lógica de IA dentro do Player
- lógica de arma dentro do GameManager

---

# 51\. Configurações

Criar arquivos/configurações centralizadas para:

- velocidade
- gravidade
- FOV
- sensibilidade
- dano
- vida
- regeneração
- duração da partida
- quantidade de bots
- respawn delay
- dificuldade
- configurações das armas

Sempre que possível, utilizar Resources da Godot.

---

# 52\. Áudio

Adicionar sistema de áudio funcional.

Sons necessários:

- disparo
- reload
- troca de arma
- hit
- headshot
- morte
- passos
- salto
- aterrissagem
- slide
- dano
- UI

Se não houver assets de áudio disponíveis, criar placeholders claramente identificados ou utilizar sons livres de uso.

Não incluir áudio proprietário de Call of Duty.

---

# 53\. Feedback visual

Adicionar:

- muzzle flash
- impacto de bala
- pequenas partículas
- shell ejection opcional
- sangue/efeito de dano estilizado e genérico
- camera shake
- hitmarker

Manter os efeitos leves para preservar performance.

---

# 54\. Sistema de debug

Criar modo debug ativável.

Durante desenvolvimento, permitir mostrar:

- FPS
- posição do jogador
- velocidade
- HP
- estado da IA
- alvo atual da IA
- quantidade de bots
- estado da partida

Adicionar opção:

DEBUG_MODE = true/false

Quando false, esconder informações de debug.

---

# 55\. Ferramentas de debug

Adicionar teclas de desenvolvimento:

F1:\
 Mostrar/esconder debug

F2:\
 Dar todas as armas

F3:\
 Regenerar HP

F4:\
 Adicionar kill

F5:\
 Restart match

Essas funções devem existir apenas para desenvolvimento.

---

# 56\. Requisitos de jogabilidade

Ao executar o projeto, deve ser possível:

1. Abrir o jogo.
2. Entrar no menu.
3. Iniciar uma partida.
4. Controlar o personagem em primeira pessoa.
5. Andar.
6. Correr.
7. Pular.
8. Agachar.
9. Deslizar.
10. Mirar.
11. Atirar.
12. Recarregar.
13. Trocar de arma.
14. Matar bots.
15. Receber dano.
16. Regenerar HP.
17. Morrer.
18. Respawnar.
19. Continuar jogando.
20. Finalizar a partida.
21. Ver o placar final.
22. Jogar novamente.

---

# 57\. Ordem de implementação

NÃO tente criar tudo simultaneamente.

Implemente em fases.

## Fase 1 — Fundação

Criar:

- projeto Godot
- Main Scene
- GameManager
- InputMap
- Player
- câmera FPS
- movimentação
- gravidade
- pulo

Primeiro garantir que o jogador consegue andar e olhar ao redor.

## Fase 2 — Combate

Adicionar:

- arma
- tiro
- dano
- HP
- morte
- reload
- munição

## Fase 3 — Segunda arma

Adicionar:

- troca de armas
- pistol
- sistema de WeaponData

## Fase 4 — Arsenal

Adicionar:

- Assault Rifle
- SMG
- Shotgun
- Sniper
- Pistol

## Fase 5 — Mapa

Criar o mapa completo de contêineres.

## Fase 6 — IA

Adicionar:

- NavigationRegion3D
- NavigationAgent3D
- bots
- visão
- ataque
- perseguição
- morte
- respawn

## Fase 7 — Movement avançado

Adicionar:

- sprint
- crouch
- slide
- camera effects

## Fase 8 — HUD

Adicionar:

- HP
- ammo
- crosshair
- timer
- kill feed
- score

## Fase 9 — Match

Adicionar:

- Deathmatch
- timer
- kills
- deaths
- respawn
- final score

## Fase 10 — Polimento

Adicionar:

- sons
- partículas
- animações
- iluminação
- menus
- configurações
- otimização

---

# 58\. Critério de conclusão

O projeto somente deve ser considerado concluído quando:

- O jogo abrir sem erros.
- O jogador conseguir entrar em uma partida.
- O jogador conseguir se movimentar.
- Sprint funcionar.
- Slide funcionar.
- Pulo funcionar.
- Crouch funcionar.
- Todas as cinco categorias de armas funcionarem.
- ADS funcionar.
- Tiro funcionar.
- Reload funcionar.
- Munição funcionar.
- Dano funcionar.
- Headshot funcionar.
- HP funcionar.
- Regeneração funcionar.
- Morte funcionar.
- Respawn funcionar.
- Bots funcionarem.
- Bots conseguirem navegar pelo mapa.
- Bots conseguirem detectar e atacar o jogador.
- Bots conseguirem morrer e respawnar.
- Kill counter funcionar.
- Death counter funcionar.
- Timer funcionar.
- Deathmatch funcionar.
- HUD funcionar.
- Tela de final da partida funcionar.
- Menu funcionar.
- Configurações básicas funcionarem.
- Não existirem erros críticos no console.

---

# 59\. Regra importante para o desenvolvimento

Você é o desenvolvedor responsável por implementar o projeto.

Não fique apenas descrevendo como fazer.

Crie efetivamente os arquivos, cenas e scripts necessários.

Sempre que criar um sistema:

1. Crie os arquivos necessários.
2. Implemente o código.
3. Integre ao projeto.
4. Verifique referências.
5. Corrija erros.
6. Execute/teste quando possível.
7. Somente depois avance para o próximo sistema.

Se alguma funcionalidade estiver temporariamente incompleta, crie uma implementação funcional mínima em vez de deixar TODOs.

---

# 60\. Prioridade

A prioridade absoluta é:

1. Jogo funcionar.
2. Gameplay ser jogável.
3. Sistemas serem modulares.
4. IA funcionar.
5. Armas funcionarem.
6. Movimento funcionar.
7. Deathmatch funcionar.
8. Mapa funcionar.
9. HUD funcionar.
10. Polimento visual.

Não gaste grande quantidade de tempo criando gráficos extremamente detalhados antes de o gameplay estar funcionando.

---

# 61\. Filosofia do projeto

Este projeto é principalmente para **aprender Godot Engine**.

Portanto, prefira soluções:

- simples
- didáticas
- modulares
- fáceis de entender
- fáceis de modificar
- bem organizadas

Sempre que houver duas soluções possíveis, prefira a que ensina melhor os conceitos da Godot sem prejudicar a jogabilidade.

O resultado final deve parecer um pequeno FPS arcade completo, funcionando como uma demonstração técnica de:

- Godot 4
- GDScript
- CharacterBody3D
- NavigationAgent3D
- Resources
- Signals
- AnimationPlayer/AnimationTree
- Raycasting
- UI
- Scene composition
- Game state management
- AI
- FPS controller
- Weapon systems
- Health systems
- Respawn systems

---

# 62\. Primeira tarefa

Antes de implementar qualquer coisa complexa:

1. Analise toda esta especificação.
2. Crie a estrutura inicial do projeto.
3. Configure o projeto Godot.
4. Configure o InputMap.
5. Crie a cena principal.
6. Crie o Player.
7. Crie câmera FPS.
8. Implemente movimento WASD.
9. Implemente mouse look.
10. Implemente gravidade.
11. Implemente pulo.
12. Crie uma pequena área de teste.
13. Execute o projeto.
14. Verifique se o jogador consegue se movimentar corretamente.

Depois disso, avance progressivamente pelas fases descritas acima.

**Não implemente todo o projeto em um único arquivo.**

O resultado deve ser um projeto Godot real, executável e organizado, e não apenas uma demonstração conceitual.