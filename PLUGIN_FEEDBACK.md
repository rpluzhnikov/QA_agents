# Kensa-QA Plugin — отчёт по сессии

Сессия: первый успешный `/new-feature` на PromoShop (24 мая 2026).
До этого было 2 сессии (164 и 215 turns), которые вызывали `/new-feature` 8 и 18 раз соответственно и **не записали ни одного файла**. Эта сессия завершилась 55 кейсами + shared step + 4 memory-апдейтами.

Отчёт пишу с позиции Lead-агента, который только что прошёл pipeline целиком.

---

## 1. Что сработало хорошо

### 1.1. Pipeline-структура `Lead → parallel Workers → review → Stage 2 → review`

Двухстадийная модель (checklist → cases) дала именно тот выигрыш, ради которого она нужна: на Stage 1 ловятся scope-ошибки до того, как накапливается стоимость написания 50+ кейсов. Все три воркера в Stage 1 вернули по 17–18 claims за ~100 секунд каждый, я проревьюил рубрикой и дал точечные правки, и Stage 2 пошёл без переписываний.

Параллелизация трёх воркеров в одном сообщении (Application / Rejections / Checkout UI) экономит wall-clock серьёзно — Stage 2 завершился за ~200 секунд при объёме ~55 кейсов.

### 1.2. Self-contained брифы заменяют отсутствующий SendMessage

`SendMessage` для продолжения воркера со стадии 1 в стадию 2 не доступен (не в deferred tools). Пришлось спавнить свежих воркеров со встраиванием утверждённого чеклиста в Stage-2-бриф. Получилось чище, чем я ожидал: воркер видит только то, что нужно сейчас, без шума из старого контекста.

### 1.3. Project memory + glossary + conventions как discoverable артефакты

`.tms/memory/` оказалась удачной структурой: project.md задаёт мета (язык, дефолты), conventions.md — стиль кейсов, glossary.md — термины. Воркеры стабильно их читали (когда я явно прописывал в брифе re-read) и выдавали кейсы в едином стиле, несмотря на то что писали независимо.

### 1.4. review-rubrics дал чёткий критерий

На Stage 1 я применял рубрику (coverage / granularity / technique / out-of-scope / open Qs / Stage 2 readiness) — все три чеклиста прошли по 6 пунктам. На Stage 2 я делал spot-check 5–7 файлов из 55 и нашёл 3 quality issue (titles не с глагола в 3 файлах, segment=ANY в 1 файле) — fix inline.

### 1.5. Workers умеют честно отчитываться

Все три воркера явно перечислили ASSUMPTIONS, DEVIATIONS, и shared-step кандидаты в финальных отчётах. Один (C) даже flagged что не смог загрузить skill md-файлы с диска — это ценная информация, потому что иначе я бы не знал что они работали по brief-injected knowledge, а не по skill-файлам.

---

## 2. Friction points

### 2.1. **Критично: `sot.yaml.notable_pages` ввёл прошлый Lead в заблуждение**

В `sot.yaml` была записана только одна страница — 655361 "PromoShop Internal Storefront for Discount Validation and Pricing Logic". Это страница-обзор, в её теле нет ни одной правила. Реальные спеки (Discount Engine, User Journey, Lifecycle, Glossary) — отдельные страницы в том же space, но прошлые сессии до них не добирались.

**Признак проблемы:** debug-сессии cbe95724 и c9fa6cc0 показывают `Files written: 0` после 8–18 вызовов `/new-feature`. Это согласуется с гипотезой: Lead каждый раз застревал на overview (нет конкретных правил → невозможно написать кейсы) → пытался задавать clarifying questions → не делегировал воркерам.

**Что починило это в текущей сессии:** я сделал CQL search по space после прочтения 655361 и обнаружил 4 дочерние страницы со спеками. После этого fetch их параллельно — план собрался за один turn.

### 2.2. Скиллы (`skill://` / `.claude/skills/`) недоступны под-воркерам

Worker C явно зарапортовал:
> No `kensa-qa` skill files found on disk (`Glob` returned no matches for `checklist-design`, `test-design-techniques`, `negative-and-edge-cases`, `web-testing`).

То есть инструкции из скиллов знал Lead (главный поток, где Skill tool работает), а воркеры — нет. Я компенсировал инлайн-инструкциями в брифе, но это дублирование контекста на каждый спавн.

### 2.3. ID-аллокация при параллельных воркерах — ручная

Я carved out три диапазона (001–019 / 020–038 / 039–055) и прописал каждому воркеру его. Если бы забыл — было бы 3 кейса с `id: 1`. Это надёжно отстреливает себе ногу, особенно когда воркеров больше трёх.

### 2.4. Тег-таксономия не покрывает `negative` и `tbd`

Воркеры на Stage 2 inevitably натолкнулись на нужду в этих тегах:
- `negative` — для всех 12 reject-кейсов
- `tbd` — для кейсов с unresolved spec gap

Оба отсутствовали в стартовой `learned/tags.md`. Я разрешил их использование и обновил taxonomy постфактум. Это первый /new-feature расширяет taxonomy — нормально, но плагин мог бы pre-seed-ить эти теги.

### 2.5. Нет fixture-registry pattern

Воркеры ввели 9 гипотетических объектов в preconditions:
- SKUs: Hoodie Lite ($35), Dress ($45), ROUNDER ($25.0125)
- Promo seeds: FUTURE10, EUDEAL, TWICE2, BOGOHOODIE, FIRSTONLY, PERCENT10, FIX_LARGE

Каждый прописан текстом в `preconditions:` соответствующего кейса. Для реального прогона это значит: либо вручную править seed-script под каждый кейс, либо кейсы не запустятся. Это вынужденная мера, но плагин мог бы давать формализованное место для регистрации фикстур.

### 2.6. Конвенции не auto-injected в под-воркеры

Каждый бриф для воркера содержит инструкцию «Read .tms/memory/conventions.md before writing». Воркер послушно читает, но это четвёртая копия одного и того же текста между Stage 1 (3 воркера) и Stage 2 (3 воркера) и финальным рефактором (1 воркер). 7 раз за сессию.

### 2.7. Сейчас нет проверки «case действительно матчит конвенции»

Я обнаружил 4 нарушения (titles не с глагола, segment=ANY) только потому что сделал spot-check 7 файлов из 55. Если бы воркеры выдали 20 кейсов с такими же ошибками — я бы их пропустил. Сейчас review-rubric для cases-stage гипотетический, нет инструмента который пройдётся по всем 55 файлам и проверит invariants.

### 2.8. `auto_save_learnings: false` корректно требует подтверждения, но poll-режим UX мог бы быть лучше

Я задал три AskUserQuestion вопроса один за другим (план, открытые вопросы, тег-таксономия, shared-steps, status flip, memory items, nit fix). Каждый — отдельный вопрос. Семь вопросов за сессию. Это не страшно, но можно было бы batched-ить.

### 2.9. `/save-memory` sentinel-гарантия мне понравилась, но...

Stop-hook требует «memory-checkpoint: done» — норм. Но если Lead «эмитнул» sentinel преждевременно (например по ошибке), вторая попытка ничего не пишет — он остаётся как valid signal. Это редкая ситуация, но flagging.

### 2.10. Past-session ничего не пишет в `.tms/` — не было guardrails

Hook пишет debug-логи `session-cbe95724-b110-4073-8dea-509512fef870.md` с показателем `Files written or edited under .tms/: (no files written in .tms/ this session)`. Это отличный сигнал — но не actionable пока кто-то не прочитает лог. Hook мог бы alerting-ить: «You called /new-feature 18 times this session but wrote 0 files. Stop and ask the user what's blocking».

---

## 3. Концретные предложения по улучшению

### Приоритет 1 — критично для DX

**P1.1. `/setup` должен auto-discover Confluence-структуру.**
После того как пользователь указал space, плагин должен сделать CQL search и предложить пользователю выбрать набор страниц в `sot.yaml.notable_pages` — не одну. Сейчас одна страница в `notable_pages` создаёт иллюзию что этого достаточно.

**P1.2. Pre-seed-ить тег-таксономию.**
`learned/tags.md` после /setup должен содержать как минимум: `smoke`, `regression`, `negative`, `tbd`, плюс project-specific теги. Сейчас `tbd` и `negative` появляются на первом же /new-feature и Lead вынужден просить user'а обновить taxonomy.

**P1.3. ID-аллокация в Lead протоколе.**
При параллельных воркерах Lead должен генерировать `--id-range NNN-MMM` в брифе автоматически (Read config.yaml.next_id, посчитать estimated count, сделать carve-out). Сейчас это done by hand и хрупко.

**P1.4. Validator для случаев.**
После Stage 2 нужен mechanical pass который проверяет:
- title начинается с глагола (по списку допустимых императивных глаголов из conventions)
- frontmatter содержит все required keys
- preconditions не пустые
- tags все из taxonomy (или с warning «tag X not in taxonomy»)
- segment values только NEW/RETURNING/VIP
- ID соответствует filename

Это можно сделать как kensa-cli команду `kensa validate suites/**/*.md`.

### Приоритет 2 — улучшает workflow

**P2.1. Fixture registry.**
Завести `.tms/fixtures/promos.yaml` и `.tms/fixtures/skus.yaml`. Кейсы ссылаются по ID:
```yaml
preconditions: |
  fixture: alice-new-us
  cart: [HOODIE×1, CAP×1]
  promo: WELCOME10
```
Плагин знает, какие fixtures используются → seed-script для реального прогона генерируется автоматически.

**P2.2. Skill files visible to sub-workers.**
Сейчас Skill tool — main-thread only. Для kensa-qa workers это означает что весь практически-применимый контент скилла (checklist-design, web-testing, etc.) приходится копипастить в brief. Если бы воркеры могли через какой-то механизм читать skill-content, брифы стали бы короче.

**P2.3. SendMessage поддержка.**
Сейчас Stage 1 worker A завершает работу с agentId `a9c33a19ae1715894` и кошельком знаний о своём чеклисте, но для Stage 2 я спавню свежего воркера и заново передаю весь контекст. SendMessage позволил бы продолжить.

**P2.4. `/coverage-extract` команда.**
После N кейсов запустить анализ: найти повторяющиеся step-последовательности (3+ steps × 3+ cases) и предложить extract в shared-step. Сейчас это делается ad-hoc — Lead вручную смотрит репорты воркеров и решает.

**P2.5. Stop-hook alerting при подозрительных паттернах.**
Если session завершилась с invocations of /new-feature ≥ 3 AND files written = 0 — emit warning «Session likely stuck. Check transcript».

### Приоритет 3 — nice to have

**P3.1. Авто-обновление `sot.yaml.notable_pages`.**
Когда Lead fetch'ит новую Confluence-страницу из space, плагин предлагает добавить её в notable_pages.

**P3.2. Auto-detect Confluence cloudId в /setup.**
Сейчас Lead должен call `getAccessibleAtlassianResources` сам. /setup мог бы сразу записать cloudId в `sot.yaml` или в memory.

**P3.3. `/tbd-list` для tracking.**
Команда, которая ищет все кейсы с тегом `tbd`, группирует по spec-вопросу и выдаёт список. Я этот реестр собрал вручную в `learned/patterns.md` — мог бы быть автоматически.

**P3.4. Status-flip автоматизация.**
Сейчас 12 кейсов в `draft` потому что у них `tbd`. Когда product закрывает spec-gap, кто-то должен пройтись по affected_cases и flipnуть status. `/resolve-tbd <question-id>` могло бы делать это.

**P3.5. Tag required_with валидация.**
В taxonomy указано `promocode requires discount`. Сейчас это просто документация. Validator мог бы enforce.

---

## 4. Что добавить (новые фичи)

### 4.1. `/spec-diff` — найти кейсы, расходящиеся со спекой

Когда Confluence-страница меняется — какие кейсы нужно пересмотреть? Сейчас это ручной поиск через `source_id`.

### 4.2. `/coverage-gap` — найти reasons/conditions без кейса

Для текущего проекта: 12 rejection reasons → 12 кейсов. Но если бы появился 13-й reason в спеке, никто не заметил бы что нет покрытия. Команда могла бы сравнить enum в спеке с тегами/title'ами кейсов.

### 4.3. `/case-link-report` — кейсы по Jira-issues

Сейчас `source_id: confluence:NNN`. Расширить до `jira:KAN-123`. Команда выдаёт: «Issue KAN-123 → 5 кейсов, 3 active + 2 draft (tbd)».

### 4.4. `/seed-extract` — генерация fixtures из preconditions

Пройтись по всем preconditions, найти все упомянутые promo + SKU, выдать seed-script для реального прогона. Связано с P2.1.

### 4.5. `/case-render` — preview кейса с inlined shared-steps

Сейчас `Use shared step: shared-steps/checkout/open-and-baseline.md` — это reference. Preview-команда заменила бы reference на тело шага inline + With-параметры → готовый текст для тестировщика, который не должен прыгать между файлами.

### 4.6. `/lead-handover` — компактный summary сессии для следующей

Когда сессия закончилась, есть смысл выдать «leftover state»: какие открытые tbd, какие fixture-имена в обращении, какие spec-вопросы ещё на product. Это сейчас в `learned/patterns.md` (я положил), но было бы хорошо генерируемой командой.

---

## 5. Оценка плагина в целом

**Сильные стороны:**
- Двухстадийный pipeline (checklist → cases) — правильное архитектурное решение, экономит токены и катит scope-ошибки рано
- Параллелизация воркеров — серьёзный wall-clock выигрыш
- Memory-структура (project/conventions/glossary/learned + sot.yaml) — discoverable, расширяемая
- `auto_save_learnings: false` + interactive checkpoint — корректная защита от drift'а в memory
- Debug-логи + Stop hook + session-snapshots — есть откуда узнать что пошло не так

**Слабые места:**
- /setup не достаточно глубоко исследует Confluence — пользователь должен сам понимать иерархию спек
- Под-воркеры не имеют доступа к скиллам — приходится копипастить контент в brief
- Нет mechanical validator кейсов после Stage 2 — quality зависит от Lead'а
- ID-аллокация ручная — хрупко
- Нет fixture-registry — реальный прогон требует ручной работы с seed-script

**Общая оценка:** плагин рабочий для проекта на ~50 кейсов за одну сессию, если Lead знает что делает. Для junior-Lead'а или для проекта с богатой Confluence-структурой нужны улучшения P1.1–P1.4.
