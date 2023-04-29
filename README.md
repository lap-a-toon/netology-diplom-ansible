# Данный репозиторий создан для автоматицации установки сервисов на виртуальные машины, созданные в облаке

## Запуск плейбука предполагается с машины-бастиона
Логины и пароли здесь храню в открытом виде. Не определился как их спрятать, впрочем, и не вижу смысла это делать в текущей конфигурации.

**В данном README не описываю порядок действий, т.к. при чтении последовательного плейбука всё вроде и так понятно. Скорее здесь будет представлено пояснение по некоторым решениям**

## Grafana

### Добавление DataSource

Был вынужден прибегнуть к предварительному удалению имеющегося DataSource, т.к. в коллекции Grafana модуль grafana_datasource при обнаружении DataSource с таким же алиасом просто падает в ошибку. Способа обойти этот момент не нашел, кроме как предварительное удаление имеющегося.

### Добавление Dashboard

1. Для обработки метрик Nginx Log Exporter за основу взял Dashboard [6482](https://grafana.com/grafana/dashboards/6482-nginx-log-metrics/)

    <details>
    <summary>Однако с ним была пара нюансов</summary>

    - при импорте через Ansible данный Dashboard не подхватывал данные из DataSource. Выявил, что в JSON-модели отсутствуют Переменные (Variables), точнее блок `__requires` - добавил в JSON-модель, в связи с чем пришлось производить импорт уже из файла, а не по ID или ссылке на Grafana Labs

    - этот дашборд не удовлетворял требованию наличия Tresholds. Я добавил их на предварительной развёртке, выставил значения, окраску значений и графа со статусами ответа серверов (200,304,404). Собственно, основываясь на личном опыте принял решение отслеживать именно 404 ошибки, которые в некоторых случаях, при высоких значениях, могут быть свидетельством атаки на сайт.

    Для теста на 404 ошибку запускал из консоли браузера на странице такой вот JS-код:
    ```
    setInterval(function(){
    $.get("/qwe.php");
    },10)
    ```
    Данный код наждые 10 миллисекунд опрашивает несуществующий файл `qwe.php` в корне сайта.

    Таким образом после кастомизации Дашборда, сохранил его JSON-модель и прописал в playbook "подкидывание" этой модели в виде файла
    </details>

2. Для мониторинга состояний серверов использовал следующий Dashboard [12486](https://grafana.com/grafana/dashboards/12486-node-exporter-full/?tab=revisions).

    <details>
    <summary>С данным дашбордом тоже оказалось не всё так просто</summary>
    при попытке указать ревизию с помошью параметра `dashbord_revision`, ansible падал в ошибку, соответственно, было решено добавлять нужную ревизию дашборда по URL на Grafana Labs.
    </details>


Плейбук старался построить без асинхронных действий чтобы было легче отслеживать его выполнение в логах бастиона и все задачи выполнялись последовательно, т.к. в некоторых местах порядок имеет критическое значение.

## ELK

Установку пакетов elastic организовал из зеркала https://mirror.yandex.ru/mirrors/elastic/8/

Создал отдельного пользователя для Elastic с ролями **superuser** и **kibana_system**.

При развёртке **kibana** и настройке **filebeat** на веб-серверах выяснил, что необходимо сначала запустить kibana, дождаться пока она начнет отдавать ответ 200 (при авторизации,естественно) и только после этого выполнять команду **filebeat setup**
Потому был вынужден применить ожидание ответа сервера с довольно большим запасом по времени.

В самом начале плейбука так же применено ожидание ответов от всех серверов, чтобы при выполнении оного не было пропущено ни одного сервера, однако, подозреваю, что это не панацея и отслеживать выполнение плейбука всё таки нужно.

Все конфигурационные файлы сложены в соответствующие каталоги (как они должны лежать на серверах) и записаны в виде шаблонов Jinja2, чтобы подмтавить логины и пароли из переменных.

Установку **node-exporter** и **prometheus**, к сожалению, не удалось сделать идемпотентной, так что реализованы в bash-скриптах, подкидываемых, как и конфиги, в виде шаблонов.

Так же для успешного запуска elasticsearch пришлось значительно увеличить предельный размер виртуальной памяти, в противном случае сервис не запускается.

Еще пришлось увеличить время на запуск сервиса elasticsearch с 75 до 210 секунд (чтобы наверняка). Причина: сервис падает не запустивший по таймауту на запуск, вероятно, из-за довольно слабых характеристик виртуальной машины.
