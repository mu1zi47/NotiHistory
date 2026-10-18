# Проверка рефакторинга

## Меню ⋮ и анимация удаления — 17 октября 2026

- Меню переоформлено: скруглённая белая карточка с названием приложения, пастельными иконками, заголовками и пояснениями действий; плавное появление через прозрачность и небольшой сдвиг за 200 мс. Открывается по долгому нажатию. Кнопка ⋮ рядом со временем удалена по следующему уточнению пользователя.
- Подписи: «Удалить уведомление», «Удалить все уведомления» с пояснением про историю этого приложения, «Отключить сохранение» с пояснением про новые уведомления.
- Удаление из меню использует тот же уход карточки в сторону и сворачивание высоты, что свайп. Групповое удаление анимирует созданные строки с короткой задержкой, затем выполняет одно удаление истории приложения. При ошибке строки восстанавливаются; взаимодействия блокируются только на время группового удаления.
- Проверки интерфейса прошли: открытие через ⋮ и долгое нажатие, промежуточные кадры анимации, удаление только целевого приложения, отмена и восстановление после ошибки.

## Меню уведомления по долгому нажатию — 17 октября 2026

- Долгое нажатие открывает контекстное меню рядом с местом касания: удалить одно уведомление, удалить все уведомления его приложения, отключить сохранение от приложения. Обычное нажатие и свайпы сохраняют прежнее поведение.
- Удаление всех уведомлений приложения требует подтверждения и охватывает всю его историю независимо от поиска и периода. Другие приложения не затрагиваются. Отключение сохранения меняет существующую Android-настройку и не удаляет историю.
- Все 46 тестов прошли, включая открытие меню, удаление одного сообщения, отмену/подтверждение удаления истории приложения, независимость других приложений и вызов отключения сохранения.

## Сброс исчезнувших приложений и пустые настройки — 17 октября 2026

- При обновлении сводки истории выбранные приложения сверяются с доступными. Исчезнувшие после очистки приложения удаляются из фильтра; лента повторно загружается с актуальным выбором. То же происходит при удалении последнего сообщения выбранного приложения. Поиск и период не сбрасываются; выбранные приложения с оставшейся историей сохраняются.
- AppEmptyState объединяет оформление пустого состояния главной страницы и настроек: фиолетовая иконка, заголовок, пояснение и действие сброса фильтров. В настройках сброс очищает запрос и возвращает показ всех приложений.
- Все 43 теста прошли, включая очистку по приложению, удаление последнего сообщения, сохранение оставшихся выбранных приложений и сброс пустого состояния настроек. Анализатор без замечаний.

## Шторка фильтра приложений — 17 октября 2026

- Фильтр настроек использует общий showHistorySheet/HistorySheet, как выбор периода на главной: скругления, затемнение, ручка, центрированный заголовок, карточки с иконками и выделением выбранного варианта.
- Все четыре теста настроек проходят, включая выбор фильтра и работу совместно с поиском.

## Фильтр состояния приложений — 17 октября 2026

- Нижняя кнопка фильтра открывает выбор: все приложения, включённые, выключенные. Выбранное состояние отражается в подписи кнопки и работает совместно с поиском.
- При изменении переключателя строка сразу покидает неподходящий фильтр. Счётчик остаётся общим; «Включить все» снимает исключения для всего списка. Для пустого состояния выводится «Нет включённых/выключенных приложений».
- Все четыре теста настроек прошли, включая фильтрацию, поиск, обновление после переключения и включение всех из отфильтрованного списка. Анализатор без замечаний.

## Единый блок приложений — 17 октября 2026

- Приложения объединены в непрерывный белый блок: разделители только между строками, скругления 20 px сверху и снизу, без внешней обводки. Скругления видимой области используют общий с главной страницей ListCornersPainter.
- Счётчик включённых приложений закреплён под верхней панелью и обновляется при изменении выбора. Пустой результат поиска не рисует скругления пустого блока.
- «Включить все» появляется и исчезает за 240 мс с изменением ширины и прозрачности. Исчезающая кнопка сразу блокируется для нажатий.
- Анализатор без замечаний. Тесты настроек проверяют промежуточные кадры появления/исчезновения, закрепление счётчика при прокрутке, отсутствие зазоров между строками, скругления и разделители без боковой обводки.

## Поиск в нижней панели настроек — 17 октября 2026

- Поиск приложений скрыт по умолчанию и раскрывается из кнопки «Поиск» в нижней панели, с той же анимацией и оформлением, что на главной странице. Поле поднимается над клавиатурой, закрытие очищает запрос.
- Панель присутствует всегда; «Включить все» появляется только при наличии выключенных приложений и занимает ширину содержимого. Общий AppActionButton обеспечивает одинаковый стиль кнопок главной страницы и настроек.
- Анализатор без замечаний. Проверки главного экрана прошли; оба теста настроек прошли, включая раскрытие/закрытие поиска, размещение над клавиатурой, компактную ширину кнопки и включение всех приложений.

## Экран сохранения приложений — 17 октября 2026

- Убраны большая иконка и заголовок «От каких приложений сохранять». Пояснение: «В историю попадают уведомления только от выбранных приложений». Описание, поиск, счётчик и список находятся в одном CustomScrollView: при прокрутке приложения занимают место вступления, верхняя панель остаётся закреплённой.
- Если есть выключенные приложения, снизу появляется панель с кнопкой «Включить все» в стиле действий главного экрана. Операция снимает все исключения одним commit в Android preferences и применяется ко всему списку независимо от поиска. Во время сохранения повторные изменения блокируются; ошибка оставляет прежний выбор.
- `flutter analyze`: без замечаний. Все 39 Flutter-тестов прошли. Новый тест проверяет прокрутку вступления, стабильное положение панели, включение скрытых поиском приложений и обработку ошибки.
- Нативная проверка на Samsung SM-A336B прошла (`INSTRUMENTATION_CODE: -1`), включая включение нескольких исключённых приложений и чтение результата новым экземпляром хранилища. Использованы отдельные тестовые preferences и база.

## Кнопка у конца списка — 17 октября 2026

- Кнопка «Наверх» скрывается, когда до конца списка остаётся не более 24 px; при прокрутке обратно появляется. По уточнению со скриншотом отступы справа и снизу равны: 8 px относительно белого блока; справа дополнительно учитываются 16 px внешнего отступа ленты.
- Все 14 widget-тестов прошли, анализатор без замечаний.

## Навигация по датам и длинная прокрутка — 17 октября 2026

- Нажатие на закреплённую дату возвращает к началу её группы; смещение берётся из layout-координат sliver-группы, а не из текущего положения закреплённого заголовка.
- Если до цели больше полутора экранов, сначала выполняется jump на расстояние 0.75 экрана от цели, затем короткая анимация 320 мс. Короткие переходы анимируются напрямую. Это ограничивает анимируемую дистанцию; измерения FPS не проводились.
- Отступы кнопки от правого края белого блока и нижнего края ленты равны. Убраны завершающий отступ группы и пустой footer без пагинации; у последнего сообщения каждой группы нет нижнего разделителя.
- Все 14 widget-тестов прошли, включая возврат к началу вчерашних сообщений, предварительный jump из конца списка, равные отступы и совпадение нижней границы последней карточки с viewport.

## Возврат наверх — 17 октября 2026

- После прокрутки более 160 px появляется фиолетовая кнопка «Наверх» над нижними действиями. Кнопка и нажатие на верхнюю панель плавно возвращают к началу за 400 мс. Кнопка скрыта и недоступна для нажатий/скринридера у начала ленты.
- Все 14 widget-тестов прошли, включая появление/скрытие кнопки, возврат обоими способами и независимую работу кнопки настроек.

## Стиль удаления свайпом — 17 октября 2026

- Фон удаления заменён на пастельный красный `#FBEAEC`, иконка — приглушённый красный `#C76370`. После раскрытия половины ширины карточки корзина плавно переходит от края к центру открытой области (180 мс).
- У каждого сообщения остаётся только нижняя разделительная линия, в том числе при свайпе.
- Анализатор без замечаний, все 13 widget-тестов прошли, включая центрирование при свайпе в обе стороны и возврат жеста перед удалением.

## Индикация удаления свайпом — 17 октября 2026

- При свайпе в любую сторону под сообщением появляется красный фон с белой иконкой корзины. Во время сдвига карточка показывает обе границы: верхнюю и нижнюю.
- Widget-проверки: фон, иконка и обе границы при сдвиге влево и вправо; отмена жеста скрывает фон и сохраняет сообщение; длинные свайпы удаляют в обе стороны. Все 13 тестов интерфейса прошли, анализатор без замечаний.

## Скругления, разделители и закреплённые даты — 17 октября 2026

- Уточнённый запрос: убрана только внешняя обводка; восстановлены скругления начала и конца групп, разделители между сообщениями и закрепление даты текущего дня. Заголовки не рисуют рамки вне своих границ.
- Widget-тест проверяет, что после прокрутки от сегодняшних сообщений к вчерашним «Сегодня» уходит, а «Вчера» закреплено непосредственно под верхней панелью (64 px в тестовом viewport).

## Удаление рамок ленты — 17 октября 2026

- По запросу пользователя полностью удалены внешняя рамка групп, скругления карточек, линии карточек и фиксированная нижняя рамка viewport.
- `flutter analyze`: без замечаний; все 37 тестов прошли.

## Пустая шапка дня — 17 октября 2026

- Заголовки дат прокручиваются вместе со своей группой. Удалены закрепление дат и рамки, рисовавшиеся за пределами заголовка: предыдущий день больше не оставляет пустую шапку над следующим. Верхняя панель приложения остаётся закреплённой.
- Добавлена проверка перехода от сегодняшней группы ко вчерашней при прокрутке. Устаревшие ожидания скруглений и отступов обновлены под текущую группировку карточек.
- `flutter analyze`: замечаний нет; `flutter test`: все 37 тестов прошли.

## Настройки сохранения — 17 октября 2026

- Общий экран настроек доступен через шестерёнку в верхней панели. Пункт «Сохранение уведомлений» открывает отдельную страницу поиска и переключателей приложений. Переход туда и возврат проверены widget-тестом. Список включает приложения с launcher-активностью, приложения из истории, сохранённые исключения и системные источники Android/System UI.
- Исключения сохраняются в Android SharedPreferences; сервис проверяет их до извлечения и записи уведомления, включая работу без Flutter. Все приложения по умолчанию разрешены; существующая история не удаляется.
- `flutter analyze`: замечаний нет. Новый widget-тест поиска, переключения, повторного открытия и ошибки сохранения прошёл. Общий набор: 35 прошли, один существующий тест скруглений ленты падает, ожидая радиус 0 вместо уже заданного в HEAD радиуса 18.
- `HistoryInstrumentation` на Samsung SM-A336B: все проверки прошли, включая настройки по умолчанию, сохранение исключения при новом экземпляре хранилища, независимость других приложений и повторное включение (`INSTRUMENTATION_CODE: -1`). Использованы отдельные тестовые preferences и база.
- Экран осмотрен на телефоне: загружены 90 приложений, текст и переключатели отображаются без переполнения. Итоговый release APK собран и установлен поверх текущей версии.

## Зарядка Samsung — 17 октября 2026

- На подключённом Samsung SM-A336B обнаружено системное уведомление `com.android.systemui` с тегом `charging_state`; Samsung удаляет и публикует его повторно.
- Для этого ключа сохраняется связь с записью истории после удаления и reconciliation; изменения процента обновляют прежнюю запись. Старые дубликаты автоматически не удаляются.
- Release APK собран и установлен поверх текущего приложения без очистки данных.
- `HistoryInstrumentation` на телефоне: `INSTRUMENTATION_CODE: -1`, все проверки прошли, включая новый сценарий 41% → удаление → reconciliation → 42% с сохранением ID и одной строки. Используется отдельная тестовая база.
- Для инструментальной проверки release-сборки временный Gradle init script отключал shrinking: при включённой оптимизации тестовый раннер терял Kotlin-класс. После проверки установлен обычный оптимизированный APK.

Проверено 3 октября 2026 года.

- `flutter analyze`: замечаний нет.
- `flutter test`: 12 тестов прошли (контроллер, platform repository, UI).
- `flutter build apk --debug`: сборка успешна.
- Android 16, `HistoryInstrumentation`: SQLite, парсер и миграция прошли, `INSTRUMENTATION_CODE: -1` (`Activity.RESULT_OK`).
- На том же эмуляторе экран приложения закрыт (активен launcher). Уведомление `NotiHistory background verification` с текстом `Saved while NotiHistory screen was closed` найдено в SQLite. Сервис был привязан Android без запуска foreground service (`startForegroundCount=0`). Это проверка закрытого экрана, не force-stop процесса.

Контроллер проверен на объединение быстрых поисковых запросов, отбрасывание устаревших ответов, очистку при незавершённом чтении, подгрузку без повторной сводки, сохранение старых страниц при обновлении, объединение событий, отсутствие запросов при скрытом UI, завершение запросов после dispose и постоянную временную границу пагинации. Репозиторий проверен на LRU-кэш и облегчённые ответы Android. UI — поиск, фильтры, подробности, отмену/подтверждение очистки и узкий экран.

Нативные проверки используют отдельную базу `history-instrumentation.db`: одинаковые уведомления, изменения текста, кириллица без учёта регистра, буквальный поиск символа `%`, фильтр приложения и даты, очистка активных уведомлений, 75 записей на двух страницах, WAL, повторное открытие и обновление v1 → v2 без потери записи. Парсер проверен на обычный и расширенный текст.

Это функциональные проверки, а не измерение FPS или расхода батареи. Ускорение в процентах не заявляется. Для большого реального архива остаётся отдельно измерить скорость поиска по подстроке и память при длительной прокрутке.

## Правки интерфейса

- Системные панели прозрачные, их контрастная подложка отключена. Лента занимает весь экран; верхний бар — часть прокрутки, нижний отступ находится внутри списка.
- Заголовок «Ваша история», поиск и очистка скрыты по умолчанию (`HistoryScreen.showActions = false`). Их обработчики и тесты сохранены.
- Выбор периода открывает отдельный bottom sheet с тремя вариантами и отметкой выбранного периода.
- `flutter analyze` без замечаний, 14 Flutter-тестов проходят, debug APK собирается. Новые проверки подтверждают скрытие элементов, выбор/отмену периода и размеры области прокрутки при системных отступах.
- Визуально проверены главный экран и bottom sheet на эмуляторе Android 16 с жестовой навигацией. Системная полоса навигации отображается поверх содержимого без отдельной подложки. Трёхкнопочная навигация отдельно не проверялась.

## Шрифты

- Заголовки — Exo2 (`assets/fonts/Exo2.ttf`), остальной текст — существующий Manrope. Nunito не подключён. Шрифты встроены в приложение, лицензии добавлены в `LicenseRegistry`.
- Exo2 подключён как вариативный шрифт Google Fonts. Начертания Manrope 600, 700 и 800 и размеры текста сохранены.
- После замены заголовков на Exo2: `flutter analyze` без замечаний, debug APK собирается. Проверка на эмуляторе Android 17 относилась к предыдущей версии шрифтов.
- Тест «Default UI hides actions and selects a period in a bottom sheet» падает не из-за шрифтов: он ищет в шторке периода кнопку с подсказкой «Закрыть», которой в `period_picker_sheet.dart` нет.

### Telegram long message capture — 2026-10-17

- Device raw notification previously contained 1266 characters while the Android MessagingStyle decoder shortened the message. Capture now reads original message bundles directly, preserving sender and complete text.
- Exact former decoder output can identify an active truncated row and update it in place; unrelated historical rows are not rewritten.
- Samsung SM_A336B instrumentation: PASS for a message over 7000 characters, multiple senders, malformed fallback, active-row repair, and persistence after reopening the database. Existing parser, storage, migration, image, and capture settings tests also passed.
- Read-only inspection of the latest three saved Muizxo rows: IDs 930/929/928 have 5482/1375/1022 characters respectively. Rows 930 and 928 end with an ellipsis; row 929 ends with the complete Lorem Ipsum sentence. No matching active notification remained in the fresh system dump, so the original payloads of these three historical records could not be compared directly.

### Telegram changing push previews — 2026-10-17

- Live user-sent tests in chat «..» reproduced a second cause: raw MessagingStyle payloads themselves initially held short previews. TEST-A later grew to 4045 characters, TEST-B from 1011 to 4095, and TEST-C initially had 1010 characters. These were child notifications (`summary=false`), so the summary-notification hypothesis was rejected.
- Schema v5 retains each snapshot's message sender, timestamp, position, and notification key. Later matching full text repairs earlier snapshots; later short previews reuse known full text. Matching requires the same identity and an exact prefix of a long ellipsized preview; ambiguous full candidates are not chosen. Deleting history also deletes its message metadata.
- Device instrumentation PASS: sequential short/full snapshots, repair of earlier rows, different chats and same-second messages kept separate, persistence after reopen/reconnect, no downgrade, Cyrillic search, cleanup. Existing parser/storage/image/settings/migration tests also passed.
- Live TEST-D verification after patch: incoming raw message grew from 1010 to 3733 characters. Original row 954 grew from 12965 to 15688 characters and ends in END-D; subsequent row 955 contains the complete text plus the short follow-up. The earlier row's saved timestamp remained unchanged.
- Open details now reload the selected notification by ID on history changes and app resume. Flutter tests: 48 passed, including completion while the details sheet remains open.
- Limitation: a notification listener cannot retrieve omitted message text from Telegram's private message store. Full text can only be filled when a subsequent notification provides it. Historical snapshots created before message identity metadata was introduced cannot all be safely reconstructed.

### Overlapping swipe deletion — 2026-10-17

- Day sliver identity previously depended on the first notification ID. Removing that row recreated the whole day's subtree and disposed a neighbouring row during its active swipe/removal animation. Day groups now use the local calendar day at midnight as their stable identity, including when notification timestamps differ within the day.
- Idle rows no longer start redundant zero-distance slide animations on every swipe selection change. NotificationCard is retained as the slide AnimatedBuilder's child instead of rebuilt on every animation tick.
- Widget regression holds the next row in a swipe while the first finishes collapsing, asserts the second State and delete background survive, then completes deletion. The existing 18 feed/widget tests passed; the regression also passed with distinct saved timestamps within the same day. Flutter analysis passed.

### Pinned notification detail controls — 2026-10-17

- Notification details now use HistorySheet's fixed header/footer: app identity, timestamp and notification title stay above the body; copy/open actions stay below it. Only the body and attached image occupy the scrolling viewport.
- Six detail widget tests passed, including a long-message regression that scrolls the body and verifies header/title/action coordinates remain unchanged. Flutter analysis and diff whitespace checks passed.

### Expandable notification/filter sheets — 2026-10-17

- Message details and both application filters use a DraggableScrollableSheet connected to their content scroll controller, supporting expansion to the full safe viewport. Detail initial height follows the message length; short messages remain compact.
- The header can resize the sheet directly. Content dragged downward at its scroll start resizes it continuously instead of triggering the former distance-only dismiss. Automatic close-at-minimum is disabled while dragging; release at the minimum closes the route. Header release either closes or settles to the initial/full height.
- Removed extra top/bottom content padding in expandable sheets. App/title information and message action buttons remain outside the scrolling body.
- All 51 Flutter tests passed. The new sheet regression verifies full expansion, ordinary content scrolling, visible movement during a held pull, staying open while held at minimum, and dismissal after release. Analysis and whitespace checks passed.

### Content-sized sheets and alignment — 2026-10-17

- Replaced draggable size fractions and estimated text height with a shrink-wrapped, constrained layout: short content uses its actual height; overflow uses the entire available safe viewport. There are no alternate expanded/collapsed resting sizes.
- Preserved drag-to-dismiss by translating the complete material surface under a held downward pull at the body scroll start or header; release dismisses or returns the surface to its original position. This does not resize the content viewport.
- Added 12px between scroll content and footer controls and restored header/body breathing room. Body content stretches to the viewport width with left-aligned text; image previews align to the top left. Display-only blank lines separate sender-labelled message lines; stored/copied text is unchanged.
- All 52 Flutter tests passed, including short/full content sizing, inability to expand by upward header drag, held pull/release dismissal, and pinned detail controls. Analysis and whitespace checks passed.
- Release APK prepared locally; installation deferred at the user's explicit request until they connect the phone.

### Image preview geometry and flight animation — 2026-10-17

- Preview layout now measures the visible bitmap rather than a full-width contain box. A rounded clip and 1px foreground border use those exact dimensions, covering all four corners while retaining left alignment.
- Viewer entry interpolates from the measured preview rectangle to the centered, aspect-preserving fullscreen image rectangle. Return starts from the displayed image bounds (including transform/drag) and ends at the same left-aligned preview. System back also follows the return animation.
- Viewer regression verifies the initial preview rectangle, an intermediate expanded size, and return near the original left edge and dimensions. Viewer gesture tests and detail tests passed; Flutter analysis and whitespace checks passed.

### App-wide deletion from filter swipes — 2026-10-17

- Each application row in the history filter now swipes left/right with the same soft delete background, trash icon, threshold haptics and slide duration as notification rows. The all-applications row remains a filter control.
- A completed swipe returns a deletion request and the draft selection from the filter. The filter route finishes closing before app-specific confirmation opens. Confirmation also finishes closing before the filter reopens on confirm, cancel, or dismiss.
- Confirmed deletion uses controller.clear(packageName), covering the app's full history regardless of search/date filters. Refreshed app counts feed the reopened filter; disappeared apps are pruned from its draft selection. Errors reopen the filter without discarding the selection.
- All 19 history screen/widget tests passed, including both swipe directions, modal sequencing, cancellation retaining draft selection, app-scoped deletion retaining the other app, and filter reopening with updated rows. Flutter analysis and whitespace checks passed.

### Single-block application filter — 2026-10-17

- All filter options now share one white block with 20px outer corners, no per-row outlines or gaps, and the same #EEECF4 bottom separators as history/settings lists. The final row has no bottom separator. Avatars and text use the settings-list sizing.
- Tap toggles an application's draft selection. Long press ensures that application is selected and immediately applies the current selection without toggling it off; long press on All applications immediately clears/applies the selection.
- Swipe deletion and confirmation/reopen behavior remain available on application rows with rectangular reveal backgrounds inside the shared rounded block.
- All 20 history screen/widget tests passed, including long press after tap, immediate application/close, reset via long press on All applications, and existing swipe confirmation/cancel/delete. Analysis and whitespace checks passed.

### App language and dark theme — 2026-10-17

- Added Settings → App settings with language/theme rows in one rounded surface block. Russian and English are supported. First launch resolves the device's preferred supported language, falling back to English, and persists the result; manual selection takes precedence on later launches.
- Theme choices: system, light and dark. Added a complete palette for backgrounds, card surfaces, text, actions, dividers, delete reveals, empty states, avatar fallbacks, menus and modal dimming. Status/navigation bar icon contrast follows the active theme. Media itself remains unchanged.
- Native `app_preferences` SharedPreferences persist both fields with validation and atomic commit on the existing worker. A failed save keeps the old visible preference. Startup loads preferences before showing history. Capture settings/history use their original independent storage.
- Added Flutter localization delegates (including Material/Cupertino built-ins), parameterized English interface strings, English Today/Yesterday/period labels and error translations. Notification contents and app names are not translated or rewritten.
- All 60 Flutter tests passed. New tests cover device locale resolution/fallback, preference restoration under another device locale, failed persistence, system brightness changes versus explicit overrides, English filters/confirmation, changing language on existing routes, and dark surface colors. Analysis/whitespace checks passed. Dark settings/history previews were rendered and visually inspected.

### Settings layout and system icon contrast correction — 2026-10-17

- App settings is now a section heading directly on the Settings page with the Language/Theme rows in one rounded block. Removed the extra AppSettingsScreen route; notification capture remains accessible below it.
- Language/theme pickers now match the shared app/filter style: centered Exo2 heading, rounded surface block, divider lines, purple icon tiles and selected checkmark. Pickers use the shared content-size/pull-to-dismiss behavior.
- Fixed HistoryAppBar's explicit light-mode system overlay style, which overrode the otherwise dynamic root/theme style. It now requests light status/navigation icons in dark mode. Startup honors device brightness, and native night styles/launch background use dark surfaces with light icons.
- All 60 Flutter tests passed after the layout change. Preference tests verify direct access on Settings and assert light status/navigation icon brightness on the actual main SliverAppBar after switching to dark mode. Updated theme/language picker previews were rendered and visually inspected. Analysis and whitespace checks passed.
