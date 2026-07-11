# kensa-qa rework plan — UX flow, hook, skills, agents (2026-07-11)

> **RU TL;DR:** полная переделка по итогам четырёхстороннего ревью (флоу команд, Stop-хук,
> скиллы, агенты). Этот файл — источник истины для продолжения работы: статусы пакетов
> ниже обновляются по мере выполнения. Если сессия оборвалась — открой этот файл,
> найди первый пакет не в статусе `[x]`, продолжи с него. Ветка: `feat/kensa-full-cli-coverage`
> (примечание: работа НЕ закоммичена до явной просьбы юзера; см. "Commit plan" внизу).
>
> Источник задач: ревью-сессия 2026-07-11. Полные отчёты сгенерированы четырьмя
> субагентами (команды/UX, агенты/rigor, скиллы/логика, hooks-schema docs); их выжимки
> вшиты в спецификации пакетов ниже — план самодостаточен.

## Status board

- [x] **A (P0)** Hook redesign — DONE (js/ps1/sh переписаны на маркер `.tms/.pending-checkpoint` и js протестирован; plugin.json → node; new/update/save-memory команды обоих движков + CLAUDE.md/AGENTS.md/test-lead-agent.md+toml переписаны; build-скрипты валидируют .js). ОСТАТКИ уходят в пакет D: (A9) setup.md — .gitignore для маркера; (A10) фразы «does not emit memory-checkpoint: done» в остальных командах обоих движков — переформулировать в «never creates the checkpoint marker» при проходе D по каждому файлу.
- [x] **B (P0)** Rubric teeth + spec attack + dimension gate — DONE (review-rubrics: критерии 3/4/8 критичные + новый критерий 8 «dimensions table» + case-рубрика send-back по негативам; checklist-design: нормативная секция gate + таблица в примере + негативы primary flows → must-have + BVA/EP пример разделён; task-assignment: приоритет-наследование негативов, kensa-test-authoring в Stage-2, fossil удалён, версия unpinned; test-lead-agent.md: always spec-attack + dimension gate + risk-ordering + ledger в отчёте + Write/Edit tools; qa-engineer-agent.md: безусловный spec-attack + Adversarial mandate (квота негативов, 70% правило, Stage-2 sweep); оба codex toml обновлены; new-feature.md Spec defects — сделан в пакете A/D связке)
- [x] **C (P0)** Skill bug fixes — DONE (NUL→`\x00`; выдуманные флаги CLI исправлены в test-monitoring + testing-fundamentals (source_ac/risk_refs → custom/tags); playwright-ci-docker: фантомный скилл → реальные имена, Browserify → Chromium sandbox, YAML-дубль → кросс-ссылка; BVA согласован на «8 items {6-9},{63-66}» во всех 4 местах + пример $48..$502; kensa-results «7 more» + @KEN конвенция + write-back шаг; source_id conflation: 4 скилла → тег `related-<id>`, конвенция в kensa-test-authoring + дерево каталогов исправлено (suites под .tms/) и дополнено; мелочь: kensa-setup→/setup, figma-use dead link→read-mostly преамбула, unpin 0.16.0 ×2, kensa-mobile exit 1, §5 dangling, sequential-thinking frontmatter, kensa description+engine-пути, {tag}-пример, learned/ пути нормализованы perl-свипом, test-tools-overview знает про automation-бандлы)
- [x] **D (P1)** Command epilogues/handover/preflight — DONE полностью (Claude 21 файл + Codex 18 промптов через субагента; verification greps: 0 «memory-checkpoint: done», 0 старых формулировок, 0 голых имён команд в codex)
- [x] **E (P1)** New commands — DONE (next/import-results/new-routine в base, automate-case в automation-playwright-ts; оба движка ×4 файла; catalog.json + engines.json обновлены; automation-test-lead: секция «Routing to sibling bundles» (codereviewer/git-operator/devops doors) + negative-parity в брифе + coverage adequacy в ревью; automation-engineer: derive-scenarios-before-code + greenfield negative rule; CLAUDE.md/AGENTS.md: новые команды + контракт эпилога)
- [x] **F (P1)** Seasoned-tester upgrades — DONE (новый скилл exploratory-testing в base+catalog, wired в qa-engineer/test-lead; оракулы в test-case-writing-craft; ledger в save-memory+отчёте Lead (сделано в A/B); pairwise worked example + CRUD×roles×states grid в test-design-techniques; strategist: Bash read-only grounding + attack-surface ось в brainstorm; schema-bootstrap: конфликт сэмплов → GAP; codex toml зеркала ×4)
- [x] **G (P1/P2)** Hygiene — DONE (Write/Edit у test-lead (в B); always-skills сведены (kensa-test-authoring в Stage-2 и new-feature); sequential-thinking guard «if installed» в обоих base-агентах; non-functional reconciled через flag-rows dimension gate; ci-flake-gating называет test-flakiness-governance; ci-artifacts: junit+blob сосуществуют; playwright-typescript дата убрана)
- [x] **H (P2)** Docs refresh — DONE (README: bundle-секция, counts 54/26/28, команды-таблицы с новыми, verify по base, hook-story + FAQ на маркер, roadmap v0.15-0.17; INSTALL: base+bundles пути копирования, verify по base, counts; CLAUDE.md/AGENTS.md; CHANGELOG 0.17.0; qa-agents-plugin.md — чист. Бонус-фикс: невалидный filter-синтаксис в audit.md tag:→tag=, mtime→modified). Примечание: README-субагент упал на session limit посреди FAQ — дочищено вручную.
- [x] **I (final)** DONE — версии 0.17.0; финальный build зелёный (54 skills, оба движка, манифесты валидны); свипы: 0 «memory-checkpoint: done» в engines/shared, 0 version-pins; смоук dist: node-хук ✓, новые команды ✓. 237 файлов изменено (213 M + 24 new, включая dist). НЕ ЗАКОММИЧЕНО — ждёт решения юзера (commit plan внизу файла).
- [x] **J (final)** Plugin Bible — DONE: `docs/BIBLE.md` (9 разделов: философия, архитектура/билд, агенты+ревью-петля+dimension gate, полный роутинг команд, карта скиллов+конвенции, память+маркер-хук, CLI-поверхность, 9 журни+troubleshooting, contributor-чеклисты)

Правило выполнения: пакеты идут по порядку A→J. Внутри пакета обновляй чекбоксы
подпунктов. После каждого пакета: отметь здесь `[x]`, проверь `git status` на мусор.

---

## Repo facts (чтобы не переоткрывать)

- Монорепо двух движков: `engines/claude` (commands `*.md`, agents `*.md`, `.claude-plugin/plugin.json`, `CLAUDE.md`) и `engines/codex` (`.codex/prompts/kensa-<cmd>.md`, `.codex/agents/<agent>.toml`, `.codex-plugin/plugin.json`, `AGENTS.md`). Общий payload: `shared/{skills,hooks,templates}`.
- `catalog.json` — единственный источник base/bundle membership. Каждая новая команда = файл в ОБОИХ движках + запись в catalog.json. Каждый новый агент = `.md` + `.toml` (toml требует `name`, `description`, `developer_instructions`).
- `engines.json` — контракт Kensa-приложения, bundle ids должны совпадать с catalog.json.
- Build: `pwsh scripts/build.ps1` (и `scripts/build.sh` — держать в паритете!). Валидация: skills 1:1 с каталогом, манифесты, hook-скрипты по списку в build-скриптах (`save-memory-stop.sh`, `save-memory-stop.ps1` — при добавлении `.js` обновить ОБА build-скрипта), codex toml поля.
- Claude Stop-hook регистрируется inline в `engines/claude/.claude-plugin/plugin.json` (exec-form: `command` + `args`, `${CLAUDE_PLUGIN_ROOT}` подставляется, `statusMessage` валиден). `shared/hooks/hooks.json` — Codex-only регистрация, build удаляет её из claude dist.
- Docs-факты о хуках (проверено по code.claude.com/docs): Stop срабатывает после КАЖДОГО хода; вход содержит `cwd`, `stop_hook_active`, `transcript_path`, `last_assistant_message`; блок = exit 0 + `{"decision":"block","reason":"…"}` (рендерит заметное уведомление) или exit 2 + stderr; тихий вариант = `{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"…"}}`; 8 блоков подряд → форс-стоп; per-platform command selection в схеме НЕТ; кроссплатформенный паттерн = `node` + один js (node уже зависимость: npx для sequential-thinking MCP).

---

## Package A (P0) — Hook redesign

**Проблема:** (1) детекция substring-ом по всему транскрипту — любое упоминание
`/new-feature` (включая будущие подсказки «дальше запусти…») перевзводит хук;
(2) сентинел `memory-checkpoint: done` — спам в чате by design; (3) Stop фиксирует
каждый ход — statusMessage крутится всегда; (4) на macOS/Linux exec-form
`"command":"powershell"` не резолвится → «hook error» после каждого хода.

**Дизайн:** маркер-файл `.tms/.pending-checkpoint` вместо сканирования транскрипта.

- [ ] A1. Новый `shared/hooks/save-memory-stop.js` (node, кроссплатформенный):
  читает stdin JSON; `stop_hook_active:true` → exit 0; если `<cwd>/.tms/.pending-checkpoint`
  НЕ существует → exit 0; иначе stdout `{"decision":"block","reason":"Memory checkpoint owed: run the save-memory protocol (commands/save-memory.md), then delete .tms/.pending-checkpoint. If .tms/memory/ does not exist, just delete the marker."}` exit 0.
  Никакого чтения транскрипта. Любая внутренняя ошибка → exit 0 (never wedge).
- [ ] A2. Переписать `shared/hooks/save-memory-stop.ps1` и `.sh` на ту же маркер-логику
  (остаются для Codex-движка; регистрация в `shared/hooks/hooks.json` не меняется).
- [ ] A3. `engines/claude/.claude-plugin/plugin.json`: Stop hook → `{"type":"command","command":"node","args":["${CLAUDE_PLUGIN_ROOT}/hooks/save-memory-stop.js"],"timeout":10,"statusMessage":"kensa-qa: memory checkpoint"}`.
- [ ] A4. `engines/claude/commands/new-feature.md` + `update-feature.md`: после
  одобрения плана юзером (перед spawn инженеров) — создать маркер `.tms/.pending-checkpoint`
  (пустой файл). Финальный шаг команды — прогнать протокол save-memory inline
  (auto-режим по `auto_save_learnings`, одна строка отчёта) и УДАЛИТЬ маркер.
- [ ] A5. `engines/claude/commands/save-memory.md`: Step 5 «Emit sentinel» → «Delete
  `.tms/.pending-checkpoint` if present». Убрать все упоминания сентинела.
- [ ] A6. Codex: `engines/codex/.codex/prompts/kensa-save-memory.md`, `kensa-new-feature.md`,
  `kensa-update-feature.md` — те же правки (маркер вместо сентинела).
- [ ] A7. `engines/claude/CLAUDE.md` секция «Memory checkpoint» + `engines/codex/AGENTS.md`
  (найти аналог) — переписать под маркер-механику.
- [ ] A8. `scripts/build.ps1` и `scripts/build.sh`: в список обязательных hook-скриптов
  добавить `save-memory-stop.js`; проверка `plugin.json missing Stop hook` остаётся.
- [ ] A9. `/setup` (`setup.md` + codex-аналог): в seeded `.gitignore` (если setup его
  трогает) добавить `.tms/.pending-checkpoint`; если setup не трогает .gitignore — добавить
  упоминание в шаге создания структуры.
- [ ] A10. Грепнуть репо на `memory-checkpoint` и `sentinel` — вычистить все остатки
  (README FAQ, skills, qa-agents-plugin.md и т.д.).

## Package B (P0) — Rubric teeth + spec attack + dimension gate

**Проблема:** `review-rubrics`: критерии 3 (Negative scenarios) и 4 (Edge cases) —
некритичные → чеклист «только happy paths» получает «approve with notes» — прямое
противоречие обещанию `negative-and-edge-cases` («Test Lead will reject»).
Атака на спеку (`static-testing-reviews`) грузится «если спека нуждается» — лазейка.
Нет проверяемого инварианта полноты покрытия.

- [ ] B1. `shared/skills/review-rubrics/SKILL.md`:
  - checklist-рубрика: критичные критерии = (1,2,3,4,5); добавить под критерий 3:
    «❌ здесь неапрувабелен ни при каких других оценках — happy-path-only чеклист
    возвращается всегда»;
  - case-рубрика: в send-back триггеры добавить «negative/edge items из одобренного
    чеклиста не реализованы»;
  - заменить «Don't invent issues to look thorough» → «Don't invent stylistic issues —
    but absence of negative/boundary/state coverage is never a stylistic issue».
- [ ] B2. `shared/skills/checklist-design/SKILL.md` — Coverage Dimensions Gate:
  обязательная финальная секция чеклиста — таблица измерений
  `negative/validation · boundaries · state transitions · permissions/roles ·
  concurrency/idempotency · interruption/recovery (cancel/refresh/offline/timeout) ·
  i18n/locale/timezone · data lifecycle (CRUD+archive) · non-functional flags
  (perf/a11y/security — flag, don't spec)`; каждая строка = covered(refs) |
  out-of-scope(причина) | N/A(почему); пустая строка invalid.
  Плюс: починить противоречие must/should (валидация и негативы primary flows →
  must-have, как в шаблоне; в should-have остаются только spec-silent edge cases);
  починить пример `[3-value BVA]` строка ~115: «6-digit non-numeric → rejected» — это EP,
  вынести в отдельную `[EP]`-группу.
- [ ] B3. `shared/skills/task-assignment/SKILL.md`: приоритет негативов наследуется от
  флоу («негатив критичного флоу = high, не medium»); в Stage-2 brief schema добавить
  `kensa-test-authoring`; удалить fossil v0.1/v0.2 «memory-keeper» (строки ~248-249);
  `generated_by: kensa-qa@0.16.0` (строка ~108) → `kensa-qa@<plugin version>` placeholder.
- [ ] B4. `engines/claude/agents/test-lead-agent.md`:
  - `static-testing-reviews` — грузить ВСЕГДА перед планированием фичи; в scope-плане
    обязательный блок «Spec defects» (противоречия/двусмысленности/пропавшие unhappy
    paths/неопределённые термины, с цитатами), даже пустой («spec reviewed, no defects found»);
  - Stage-1 review: «Dimension gate — каждая строка таблицы измерений заполнена;
    пустая/отсутствующая строка = автоматический send-back; out-of-scope строки
    копируются в отчёт юзеру»;
  - отчёт юзеру: кейсы упорядочены/помечены по risk tier, если есть risk-артефакт.
- [ ] B5. `engines/claude/agents/qa-engineer-agent.md`:
  - шаг 2: «If the spec needs a testability review…» → безусловно: «Run the
    static-testing-reviews pre-write checklist against your references before listing
    claims — always. Flag every ambiguity/contradiction/missing unhappy path with GAP:;
    an empty findings list must be stated explicitly»;
  - новая секция «Adversarial mandate» (после Workflow): default assumption — автор
    спеки забыл unhappy paths; на каждый позитивный флоу ≥1-2 негатива + boundary/state
    item где применимо (сюда же вынести из scope-analysis эвристику «AC → positive +
    1-2 negatives» — инженер её сейчас не видит); пакет с >70% happy-path требует
    явного обоснования, иначе send-back; на Stage 2 повторный прогон таксономии
    `negative-and-edge-cases` как финальный sweep перед отчётом.
- [ ] B6. `engines/claude/commands/new-feature.md`: в обязательные секции плана (Step 4)
  добавить «Spec defects». (Синхронно codex `kensa-new-feature.md`.)
- [ ] B7. Codex-зеркала: `engines/codex/.codex/agents/test-lead-agent.toml`,
  `qa-engineer-agent.toml` — внести те же смысловые правки в developer_instructions.

## Package C (P0) — Skill bug fixes

- [ ] C1. `shared/skills/security-testing/SKILL.md:342` — заменить сырой NUL-байт (0x00)
  на текст `` `\x00` `` (файл сейчас детектится как бинарный).
- [ ] C2. Выдуманные kensa CLI флаги:
  - `test-monitoring-control-completion/SKILL.md`: L68/126 `kensa stats --by-status` →
    `kensa stats` (в выводе уже есть by_status buckets); L125 `stats --by-suite` →
    `kensa coverage --by-suite`; L128 `coverage --by-risk <id>` → удалить или через
    `kensa filter "tag=risk-<id>"`; L107/127/224/300 `coverage --by-source LIN-89` →
    `coverage --by-source` (флаг без значения; сверить синтаксис по `kensa/SKILL.md:314`).
  - `testing-fundamentals/SKILL.md`: L212-213 те же фиксы; L202-203 `source_ac:`/`risk_refs:`
    пометить как custom-поля через `schema apply` или убрать; L264 ссылка на
    `reading-existing-codebase` (чужой плагин) — удалить/заинлайнить.
- [ ] C3. `shared/skills/playwright-ci-docker/SKILL.md`: L3,6,41 «kensa-qa CI/devops skill»
  (не существует) → `ci-runners-and-parallelism` / `ci-artifacts-and-reporting`;
  L10 «Browserify-style sandboxing» → «Chromium's sandbox»; дублированный shard/merge
  YAML → заменить кросс-ссылкой на `ci-runners-and-parallelism`.
- [ ] C4. `shared/skills/test-design-techniques/SKILL.md` — 3-value BVA согласовать на
  «8 items»: {6,7,8,9} и {63,64,65,66} для диапазона 8–64 (соседи ОБОИХ граничных пар
  7|8 и 64|65). Править: warning L184-190 (примеры в нём), discount worked example
  L229-236, summary table L662 («4 values per simple range» → согласовать).
  Синхронно `checklist-design` если там есть числа BVA.
- [ ] C5. Traceability seam:
  - `kensa-results/SKILL.md`: L3 «and 8 more» → «and 7 more» (форматов 11); в id-tagged
    strategy явно назвать формат `@KEN-<id>`; в orphan-remediation добавить финальный шаг
    «write `@KEN-<newCaseId>` into the test»;
  - `source_id` conflation: `kensa-browser:149`, `kensa-mobile:128`, `kensa-http:132`,
    `kensa-results:113` передают внутренний case id в `--source-id` (поле для внешних
    рефов по `kensa-test-authoring:81`). Решение: ПРОЧИТАТЬ `kensa/SKILL.md` (механизмы
    тегов/полей) и выбрать: (a) tag `related-<CASE-ID>`, или (b) префикс `case:<ID>` в
    source_id с описанием конвенции в `kensa-test-authoring`. Применить единообразно в
    4 файлах + задокументировать в `kensa-test-authoring`.
- [ ] C6. Мелочь: `test-planning:133` «kensa-setup skill» → «/setup command»;
  `figma-use:17` битая ссылка `../figma-generate-design/SKILL.md` → убрать (+ преамбула
  «в kensa-qa обычно нужны только read-скрипты §8»); `test-case-writing-craft:39`
  unpin `@0.16.0`; `kensa-mobile` добавить exit-code 1 row (паритет с browser/http);
  `playwright-test-data:62` dangling «§5»; `sequential-thinking` frontmatter: убрать
  `Write`, `Bash (*)` → `Bash(*)`; `kensa/SKILL.md:3` — дописать trigger conditions в
  description; `kensa:368,692` engine-пути `commands/*.md` → «/adapt-schema command»;
  `test-code-review-standards:40-46` канонический пример → `{ tag: '@KEN-412' }`;
  memory-пути `learned/…` → `.tms/memory/learned/…` в 7 скиллах (risk-based-testing:106/260/357,
  testing-fundamentals:57, scope-analysis:26, sdlc-and-test-lifecycle:344,
  clarification-protocol:123, test-case-writing-craft:253, test-planning:154);
  `kensa-test-authoring:33-53` дерево дополнить (`.tms/tools/http/`, `.tms/automation-runs/`,
  `.tms/blueprints/`, `.tms/memory/`, `.tms/routines/`, `.tms/reports/`);
  `test-tools-and-automation-overview:20-27` — абзац про automation-бандлы (роутить в
  `automation-test-lead`/`playwright-*` если установлены, вместо «плагин не пишет автоматизацию»).

## Package D (P1) — Epilogues + routing + handover + preflight

**Эпилог-шаблон** (добавить в конец КАЖДОЙ команды, адаптируя маршруты):

```markdown
## Epilogue (required)

End your final message with exactly this block (fill in specifics):

✅ **Done:** <one line — what was produced, counts, file paths>
➡️ **Next:** <1-3 bullets from the routing table below; each names a command and WHY.
Only suggest commands whose bundle is installed — otherwise name the bundle instead.>
```

**Routing table (source → next):**
- `setup` → `/new-feature <ref>` (первая фича); `/run-routine` (если сеяли рутины); `/adapt-schema` (если есть экспорт из другой TMS)
- `new-feature` → `/traceability` (проверить трассировку новых кейсов — qa-analytics); `/audit` (периодическое здоровье базы); `/automate-case <id>` (если automation-бандл)
- `update-feature` → `/traceability`; `/audit`
- `audit` → `/analyze-cases` (семантический слой — qa-analytics); `/update-feature <ref>` (контентные фиксы); `/traceability` (покрытие требований)
- `analyze-cases` → `/update-feature` / `/new-feature` (закрыть гэпы); re-run `/audit` после фиксов
- `pull-context` → `/review-spec <ref>` (спека шаткая); `/risk-assess <ref>` (глубина покрытия); `/new-feature <ref>` (новая фича); **`/update-feature <ref>` (spec supersedes existing cases — сейчас этот маршрут потерян)**
- `review-spec` → `/risk-assess <ref>` или `/new-feature <ref>` (pass); вопросы к продукту (needs-rework)
- `risk-assess` → `/test-plan <epic>` (агрегация); `/new-feature <ref>` (с depth guidance)
- `test-plan` → `/new-feature <ref>` × N (исполнение плана)
- `traceability` → `/new-feature <source>` (гэпы); `/update-feature` (битые рефы)
- `brainstorm` → `/new-feature <ref>` (уже есть — сохранить)
- `save-memory` → терминальная (эпилог: что сохранено + `/next` для ориентировки)
- `adapt-schema` → GUI Universal-format import → `/setup` (режим update: выучить конвенции из импортированных кейсов) → `/audit` (baseline)
- `run-routine` → `kensa new` defect (уже есть); `/new-routine` (изменить/добавить рутину); `/save-memory`
- `blueprint` → внутренние (list→show→new→validate→run — есть); наружу: `/run-routine`
- `scaffold-playwright` → `/add-auth-setup` → `/add-page-object`; потом `/automate-case <KEN-id>`
- `add-page-object` → `/automate-case <KEN-id>` (первый спек с новой fixture); `/add-visual-test <component>`
- `add-auth-setup` → `/add-page-object` (первая авторизованная страница)
- `add-visual-test` / `add-a11y-test` → `/fix-flake <spec>` (если флейкает); `/automate-case` (следующий кейс)
- `fix-flake` → `@automation-devops` (CI-гейтинг флейков — если automation-devops бандл; иначе назвать бандл)
- `automate-case` (новая) → `/add-visual-test`/`/add-a11y-test` (спец-слои); `@codereviewer` (если бандл); `@git-operator` (коммит — если бандл)
- `import-results` (новая) → orphan loop (`kensa new` + `@KEN` write-back); `/traceability`
- `next` (новая) → сама является маршрутизатором
- `new-routine` (новая) → `/run-routine <RT-id>`

- [ ] D1. Пройти все 21 существующие команды `engines/claude/commands/*.md`: добавить
  эпилог по шаблону + маршруты из таблицы. Одновременно в каждом файле:
  - **preflight-унификация**: memory exists → иначе «run /setup first and stop»;
    `kensa --version` там где нужен CLI (обязательно добавить в: new-feature,
    update-feature, adapt-schema, blueprint, save-memory (мягкий: только memory-check),
    run-routine); у /audit починить порог «<5 cases» vs текст «~20+»;
  - **bundle guards**: new-feature Step 5 platform-скиллы «if the platform-testing
    bundle is installed — otherwise proceed without it»; new-feature Step 4 + test-plan
    «suggest /brainstorm (strategist bundle — name it if absent)»;
  - **argument-hint** frontmatter везде где есть аргументы (сейчас только у blueprint,
    adapt-schema);
  - naming drift: «qa-engineer workers» → «qa-engineer-agent workers» (analyze-cases,
    review-spec, test-plan, traceability);
  - унифицировать поведение automation-команд при отсутствии проекта: как в
    add-auth-setup («run /scaffold-playwright first and stop») — добавить в
    add-page-object, add-visual-test, add-a11y-test.
- [ ] D2. **Handover reading**: `new-feature.md` (перед Step 4) и `update-feature.md`:
  «Check `.tms/reports/` for `context-<ref>-*.md`, `spec-review-<ref>-*.md`,
  `risk-<ref>-*.md` and `.tms/brainstorms/*` matching the ref; fold them in instead of
  re-gathering (newest wins; say which artifacts you used in the plan)».
- [ ] D3. Codex-зеркала: те же правки во всех `engines/codex/.codex/prompts/kensa-*.md`
  (структура файлов проще — переносить смысл, не буквально).

## Package E (P1) — New commands + doors

Каждая команда = `engines/claude/commands/<name>.md` + `engines/codex/.codex/prompts/kensa-<name>.md` + запись в `catalog.json`.

- [ ] E1. `/next` (base). Read-only маршрутизатор «что дальше»: проверяет состояние —
  `.tms/` есть? memory есть? (нет → /setup или /adapt-schema); `kensa stats` (пустая
  база → /new-feature); свежие отчёты в `.tms/reports/` (незакрытый handover →
  предложить целевую команду); маркер `.tms/.pending-checkpoint` (→ /save-memory);
  давность последнего audit; gaps из traceability. Выводит 2-3 рекомендации с
  причинами. НЕ пишет файлы. Имя `next` (не «status» — конфликт со встроенным /status).
- [ ] E2. `/import-results <report-path>` (base; skill `kensa-results` уже в base).
  Тонкая обёртка: препроверки (файл есть, kensa на PATH) → `kensa results import` →
  matched/orphaned split → orphan loop (предложить `kensa new` + `@KEN-<id>` write-back
  в тест) → эпилог (`/traceability`).
- [ ] E3. `/new-routine [name]` (base). Интервью → создать `.tms/routines/RT-NNN.md` по
  шаблону из `shared/templates/routines/` → эпилог (`/run-routine RT-NNN`).
- [ ] E4. `/automate-case <KEN-id|ref>` (bundle `automation-playwright-ts`, добавить в
  catalog.json commands). Экспонирует downstream-режим `automation-engineer`:
  препроверки (Playwright-проект есть → иначе /scaffold-playwright; кейс существует) →
  automation-test-lead формирует бриф (включая негативы кейса — см. F5) → engineer пишет
  `@KEN-<id>`-tagged спек → прогон → отчёт. Эпилог: codereviewer/git-operator doors.
- [ ] E5. Doors для agent-only бандлов:
  - `automation-test-lead.md`: routing note — «если установлен `automation-codereview` —
    делегируй ревью-проход `codereviewer` вместо самостоятельного; если `automation-git` —
    передай законченную работу `git-operator`»;
  - эпилоги `scaffold-playwright`/`fix-flake` (из D1) называют `@automation-devops`.
- [ ] E6. catalog.json: base.commands += `next`, `import-results`, `new-routine`;
  automation-playwright-ts.commands += `automate-case`. Проверить engines.json — там
  только bundle ids (командные списки не дублируются? проверить; если дублируются — обновить).
- [ ] E7. CLAUDE.md + AGENTS.md: секцию «Commands» дополнить новыми командами.

## Package F (P1) — Seasoned-tester upgrades

- [ ] F1. Новый скилл `shared/skills/exploratory-testing/` (base; catalog.json base.skills +=).
  CTFL §4.4.2 (FL-4.4.2): чартер-шаблон «explore <target> with <resources> to discover
  <information>»; Whittaker-туры (feature tour, data tour, interruption tour, adversarial
  tour…); time-boxing; session notes → `.tms/reports/session-<date>.md`; находки →
  `kensa new` defect cases. Wire: `qa-engineer-agent.md` browser/mobile секции +
  `kensa-browser` skill упоминание; `/run-routine` может предложить exploratory-сессию.
  ISTQB-grounding block по образцу соседей.
- [ ] F2. Test oracles → `shared/skills/test-case-writing-craft/SKILL.md`: секция «Where
  does the expected result come from?» — spec oracle (цитируй в source context),
  consistency oracle (как соседние фичи), cross-product oracle, heuristic oracle;
  правило: expected result без идентифицируемого оракула = `ASSUMPTION:` by definition.
- [ ] F3. Assumption ledger: `save-memory.md` (+codex) — свипать все `ASSUMPTION:`/`GAP:`
  маркеры сессии в `.tms/reports/assumptions-<ref>-<date>.md` (standing questions-to-PM);
  `test-lead-agent.md` reporting protocol — ссылаться на ledger вместо «max 3-5 items»
  (кап остаётся для чата, ledger безлимитный).
- [ ] F4. `shared/skills/test-design-techniques/SKILL.md`: добавить pairwise mechanics
  (worked example, не только «use PICT») и секцию CRUD×roles×states permission matrix.
- [ ] F5. Automation rigor: `automation-test-lead.md` брифинг += «state which
  negative/edge behaviours of the case must be automated — E2E только по happy row
  кейса с негативными шагами = incomplete»; review-проход += проверка адекватности
  покрытия vs шаги кейса. `automation-engineer.md` greenfield rule: «derive scenarios
  before code: main + key negatives from the spec; greenfield spec-file только с
  happy-path тестами обязан объяснить почему».
- [ ] F6. `strategist.md` + `brainstorm.md`: добавить ось «Attack surface» («failure
  modes и abuse cases — И ЕСТЬ scope»); дать strategist Bash + read-only `kensa stats`/
  `kensa list` ИЛИ убрать давление «Name numbers… pick even when guessing» (выбрать
  первое — добавить Bash в tools frontmatter с ограничением read-only verbs).
- [ ] F7. `schema-bootstrap-agent.md`: флажить внутренние противоречия между 1-2
  сэмплами вместо молчаливого примирения.
- [ ] F8. Codex-зеркала всех правок F (toml developer_instructions + prompts).

## Package G (P1/P2) — Cross-agent hygiene

- [ ] G1. `test-lead-agent.md` frontmatter tools += `Write, Edit` (6 команд требуют от
  него писать отчёты).
- [ ] G2. Унифицировать 4 списка «always skills» (qa-engineer-agent step 1 /
  test-lead-agent Always block / task-assignment brief schemas / new-feature Step 5):
  канон = testing-fundamentals, sdlc-and-test-lifecycle, collaboration-based-approaches
  (сессионные) + kensa-test-authoring, test-case-writing-craft, test-design-techniques,
  negative-and-edge-cases, checklist-design (Stage-бриф). Stage-2 схема в task-assignment
  ОБЯЗАНА включать kensa-test-authoring.
- [ ] G3. `sequential-thinking` — bundle-gated (strategist): в base-агентах ссылки
  обернуть «if installed»; platform-скиллы — see D1 bundle guards.
- [ ] G4. Reconcile non-functional правило: `checklist-design` («perf — отдельная
  дисциплина») vs qa-engineer step 6 / risk-based-testing (High risk → non-functional
  checks): правило = non-functional item'ы في чеклисте допустимы как FLAG-строки
  (dimension gate: non-functional flags), спеки по ним — отдельная работа.
- [ ] G5. Прочее из отчётов: `kensa-browser` vs `kensa-mobile` описания — усилить
  платформенные триггеры; `ci-flake-gating` — назвать `test-flakiness-governance` по
  имени; junit-per-shard vs blob-merge — один абзац reconcile в `ci-artifacts-and-reporting`;
  `playwright-typescript` «Current as of June 2026» — убрать дату или обновить.

## Package H (P2) — Docs refresh

- [ ] H1. README.md: bundle-архитектура (каталог бандлов: id, что даёт, default:false);
  счётчики скиллов (53+новые); roadmap v0.14 «current» → 0.17; hook story (маркер, не
  сентинел; «on Windows» claim убрать); Commands table += run-routine, adapt-schema,
  blueprint, automation-команды, новые (next, import-results, new-routine, automate-case);
  Verify-секция: /help показывает только base + установленные бандлы; «20 of the 33
  skills» и img alt «31 skills» — исправить; scoping claim «every reasoning skill cites
  ISTQB» → «base reasoning skills» (17 automation-скиллов без блока — либо добавить
  «Non-ISTQB tooling» блоки, минимум — скоуп클레йма).
- [ ] H2. INSTALL.md: тот же bundle-рефреш, verify-инструкции.
- [ ] H3. CLAUDE.md (engines/claude) + AGENTS.md (engines/codex): новые команды, новый
  hook-механизм, dimension gate, /next. qa-agents-plugin.md — проверить на устаревшее.
- [ ] H4. CHANGELOG.md: запись 0.17.0 со всеми изменениями.

## Package I (final) — Version + build

- [ ] I1. Версия 0.17.0: `engines/claude/.claude-plugin/plugin.json`,
  `engines/codex/.codex-plugin/plugin.json`, `engines.json`, catalog если есть.
- [ ] I2. `pwsh scripts/build.ps1` → validation green; `git status` — dist перегенерирован.
- [ ] I3. Смоук: `Get-Content dist/claude/base/.claude-plugin/plugin.json` — Stop hook
  = node; `dist/claude/base/hooks/` содержит js; grep dist на `memory-checkpoint:` — пусто.

## Package J (final) — Plugin Bible

- [ ] J1. `docs/BIBLE.md` — полное описание работы плагина. Outline:
  1. Философия и границы (пишет мануальные кейсы; не запускает/не заменяет runner).
  2. Архитектура: base+bundles, два движка, build pipeline, catalog.json контракт.
  3. Агенты: роли, режимы, кто кого зовёт, file bus, ревью-петля (2 stage × 2 rounds),
     rubric fail-условия, dimension gate.
  4. Команды: полный каталог с журни-картами (маршрутная таблица из пакета D),
     preflight-контракты, human gates, read-only матрица.
  5. Скиллы: карта 50+ скиллов по группам, когда что грузится, ISTQB-grounding.
  6. Память и хук: .tms/memory/*, маркер-механика чекпоинта, auto_save_learnings.
  7. CLI-поверхность kensa: какие команды каких verbs требуют.
  8. Типовые сценарии end-to-end (7 журни из ревью) + troubleshooting.
  9. Конвенции контрибьютора: как добавить команду/агента/скилл/бандл (оба движка!).

## Commit plan (когда юзер попросит)

Логичная разбивка: (1) hook redesign; (2) rubric+agents teeth; (3) skill fixes;
(4) command epilogues+routing; (5) new commands+catalog; (6) new skills+agent upgrades;
(7) docs; (8) build 0.17.0 + dist. Conventional commits, по образцу истории репо.
