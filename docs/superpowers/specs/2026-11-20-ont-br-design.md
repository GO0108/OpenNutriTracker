# OpenNutriTracker BR (fork pessoal): especificação

**Data:** 2026-11-20
**Base:** OpenNutriTracker 2.7.0 (`simonoppowa/OpenNutriTracker`, commit `5048a9b`), Flutter 3.44.6, GPL-3.0.
**Usuário:** uma pessoa, Android (Samsung), estudante/frequentador da Unicamp. Meta: perder 10 kg até fevereiro de 2027.

## O que já existe no upstream (não reimplementar)

- Registro por texto, foto e voz: `BulkAddScreen` → `ReadMealTextUseCase`/`ReadMealPhotoUseCase` → `MealItemsApi` (Anthropic suportado, chave do próprio usuário) → itens `ParsedMealItem` (sem calorias) → `ResolveParsedMealsUseCase` busca no banco → tela de revisão → diário. A IA só nomeia o alimento e a quantidade; as calorias sempre vêm de um banco.
- Ditado em pt-BR pelo reconhecedor do Android (`speech_to_text`, fallback `pt_BR`). Reconhecimento na nuvem do próprio Android é aceitável.
- Importação de treinos e calorias gastas do Health Connect (`ImportWorkoutsUsecase`), que recebe dados do Samsung Health.
- Meta calórica por TDEE + ritmo semanal (`weeklyWeightGoalKg` × 1100 kcal/dia), peso-alvo, piso de kcal (1500 H / 1200 M), divisão de macros configurável.

## Requisitos

R1. **TACO como banco principal.** A TACO 4ª ed. (NEPA-UNICAMP, 2011, 597 alimentos) vem embutida no app, funciona offline e entra tanto na busca manual quanto na resolução dos itens ditos/fotografados. Para consultas em português, um alimento TACO compatível vence produtos do Open Food Facts e registros USDA. Variantes cruas não são escolhidas a menos que a consulta diga "cru/crua". Apelidos comuns ("arroz branco", "feijão") apontam para o item certo. Alimentos comuns têm medidas caseiras (concha, escumadeira, unidade, fatia) para que "2 ovos" ou "1 concha de feijão" virem gramas. Atribuição: "TACO – NEPA/UNICAMP".

R2. **Cardápio do RU da Unicamp.** Na tela de adicionar refeição, um botão abre o cardápio do dia de `https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php?d=AAAA-MM-DD` (Almoço, Almoço Vegano, Jantar, Jantar Vegano e Café da manhã quando houver). Ao escolher uma refeição, o app monta um texto com porções padrão em gramas e abre a tela de revisão existente com esse texto. O usuário confere e ajusta antes de registrar. Quando um item varia por restaurante ("LARANJA (RU, RA e HC) / MAÇÃ (RS)"), vale a variante do restaurante escolhido (padrão RU). Sem cardápio ou sem rede, o app diz isso e não quebra.

R3. **Samsung Health.** Além dos treinos (já existentes), o peso registrado no Samsung Health (balança ou manual) entra no histórico de peso do app via Health Connect, no máximo uma leitura por dia, sem sobrescrever pesos digitados no app. Usa a mesma chave "importar do Health Connect" que já existe.

R4. **Meta por data.** O usuário informa peso-alvo e data-alvo (padrão 28/02/2027). O app calcula o ritmo semanal necessário e grava em `weeklyWeightGoalKg`. Se o ritmo passar de 1,0 kg/semana, o app usa 1,0, avisa e mostra a data mais cedo alcançável com segurança. O piso de kcal existente continua valendo.

R5. **Adequação nutricional do dia.** Na tela inicial, um cartão mostra:
- kcal ingeridas × meta (ok dentro de ±10%);
- % das kcal dos macros vindas de carboidrato, gordura e proteína × faixas AMDR (carb 45–65%, gordura 20–35%, proteína 10–35%);
- proteína em g/kg de peso corporal × mínimo de 1,6 g/kg, uma referência comum durante déficit calórico (constante ajustável).
Sem registros no dia, o cartão mostra "sem dados" em vez de números.

## Fora do escopo

Tradução da interface para português (o upstream não tem `intl_pt.arb`; strings novas vão para `intl_en.arb`, seguindo o AGENTS.md). Escrita de dados no Health Connect. Coach em chat. Café da manhã do RU, se a página não o publicar.
