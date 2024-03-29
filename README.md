# README (in Ukrainian)

Цей Web-додаток розгорнуто на власному хостингу /
This Web application is deployed on my own hosting: https://diplomas-rails.vladloz.pp.ua/

Web-додаток призначений для підготовки до друку документів про вищу освіту на основі замовлень із Єдиної державної електронної бази з питань освіти (ЄДЕБО).

Перелік документів, які можна згенерувати за допомогою цього додатку (після завершення його розроблення):
1. Диплом молодшого бакалавра.
2. Диплом молодшого спеціаліста (застарілий).
3. Диплом бакалавра.
4. Диплом спеціаліста (застарілий).
5. Диплом магістра.

Також з його допомогою можна згенерувати дублікати дипломів, зазначених у п.п. 1-5.

Вхідною інформацією для додатку є:
1. Файли замовлень на дипломи у форматі XML, які вивантажені з ЄДЕБО і містять дані про осіб, яким повинні бути видані дипломи.
2. Файли шаблонів у форматі Microsoft Word (.dotx), які містять форми дипломів, затверджені МОН України.  

Результатом є файли дипломів у форматі Microsoft Word 2007+ (.docx), у яких дані випускників вписані у форми дипломів.
Усі файли дипломів однієї генерації упаковано в zip-архів.

Web-додаток створено з використанням фреймворку Ruby on Rails: 
Ruby version 3+; Rails version 7.0.
XML-файли замовлень і zip-архіви з файлами дипломів зберігаються 
з використанням технології Active Storage.

# Завдання (tasks), які було вирішено в процесі розроблення:

1. Створити модель Order для зберігання замовлень у сховищі, контролер, і в'юшку, в якій має бути назва додатку, короткий опис призначення і форма для завантаження замовлень. У контролері створити два методи: 
   - index - формує перелік замовлень;
   - create - завантажує замовлення з комп'ютера користувача у сховище.
2. Після того, як у методі create буде завантажено хоча б один XML-файл, необхідно доповнити в'юшку формою для видалення замовлень і списком завантажених замовлень.
3. Написати тести для пп. 1 і 2. 
4. Створити у контролері метод delete_all для видалення замовлень з бази даних і сховища. Доповнити тести.
5. Створити на в'юшці форму для генерації дипломів. Підготувати файли шаблонів дипломів у форматі Word (.dotx) і розмістити їх у каталозі /public/templates.
6. Створити модель Diploma для розміщення згенерованих дипломів у сховищі. Доповнити тести.
7. Створити у контролері метод get_diplomas, який повинен парсити XML-файл кожного замовлення і, застосовуючи відповідний шаблон, генерувати docx-файли дипломів і зберігати їх у cховищі.
8. Доповнити метод get_diplomas кодом для створення zip-архіву з файлами дипломів і вивести на в'юшку посилання для скачування цього zip-архіву на комп'ютер користувача. Доповнити тести.
