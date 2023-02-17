# real-estate-db

## Założenia projektu
Celem było zaprojektowanie bazy danych dla firmy zajmującej się pośrednictwem w sprzedaży nieruchomości. Posługując się przykładowym zbiorem danych z https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques zaprojektowane zostało dziesięć tabel obsługujących m.in. lokalizację nieruchomości, zmiany ceny w ogłoszeniu na przestrzeni czasu oraz atrybuty samej nieruchomości. Baza została wyposażona w funkcje pomagające w analizie rynku nieruchomości.

## Tabele
Baza danych składa się z poniższych tabel:
1. Właściciele <br>
![image](https://user-images.githubusercontent.com/68378289/219681857-1b4622ae-007e-452b-b56f-82e5e2d38e38.png)
2. Miasta <br>
![image](https://user-images.githubusercontent.com/68378289/219682052-49201dfd-c7b7-4b39-87bd-742108438530.png)
3. Dzielnice <br>
![image](https://user-images.githubusercontent.com/68378289/219682270-e0151a73-5339-4dd8-a010-48dbb43f2e13.png)
4. Lokalizacje <br>
![image](https://user-images.githubusercontent.com/68378289/219682355-b7bb445b-c782-4310-85b8-c880740fb069.png)
5. Domy <br>
![image](https://user-images.githubusercontent.com/68378289/219682497-2ae524f9-58d3-4904-964f-26da20b15d43.png)
6. Oferty <br>
![image](https://user-images.githubusercontent.com/68378289/219682753-bc63fdcf-20f1-4f51-88a7-039cfe2a97f6.png)
7. Oferty zakończone <br>
![image](https://user-images.githubusercontent.com/68378289/219682819-5cc16d2b-33df-4d50-bf98-1b750443b00c.png)
8. Zmiany cen <br>
![image](https://user-images.githubusercontent.com/68378289/219682898-a89d56cb-c038-46e8-81ef-3ca28d965a06.png)
9. Piwnice <br>
![image](https://user-images.githubusercontent.com/68378289/219682957-e48acc63-0621-4c9a-a899-f60c6e502c6e.png)
10. Garaże <br>
![image](https://user-images.githubusercontent.com/68378289/219683024-d8961848-14f9-48f8-af2d-0e040183f4bc.png)
 <br>
Tabele 7 i 8 używane są do przechowywania i analizy danych historycznych. Tabele 9 i 10 Są oddzielone od tabeli 5 według schematu dziedziczenia - znajdują się w nich tylko rekordy dla domów które posiadają odpowiednio piwnicę lub garaż. Tabele 2, 3 i 4 mają strukturę hierarchiczną dzięki czemu łatwo wykonywać zapytania agregujące według danej dzielnicy lub miasta.

## Widoki
1. Aktualne oferty <br>
![image](https://user-images.githubusercontent.com/68378289/219684014-abcd13b9-5e6d-4294-9b35-8303d3512535.png)
2. Ostatnie zmiany ceny według oferty <br>
![image](https://user-images.githubusercontent.com/68378289/219684184-821262fa-afb7-479d-9ca5-4f27415404b6.png)
3. Ile domów udało się sprzedać danemu właścicielowi <br>
![image](https://user-images.githubusercontent.com/68378289/219684337-daeeb853-0fbb-4da8-aa2b-2a4e75932c31.png)
4. Dzielnice według liczby lokalizacji w nich zarejestrowanych <br>
![image](https://user-images.githubusercontent.com/68378289/219684685-18804d78-b6b8-4b02-91bb-c70afc271df1.png)

## Funkcje
Zmiany cen w danym przedziale czasowym <br>
![image](https://user-images.githubusercontent.com/68378289/219684849-944448d3-7508-4d8f-8f08-39f8cd6cf586.png)
 <br>
Funkcja ma służyć do ułatwienia analizy danych czasowych - Zwraca dane tylko dla ofert, których przedział istnienia ogłoszenia w pełni zawiera przedział dany argumentem, tzn. dla danego dnia będzie jednoznacznie zdefiniowana cena każdej oferty znalezionej w tabeli wynikowej. Funkcji można użyć np. do policzenia średniej ceny oferty w danym przedziale czasowym, ale ze względu na przypadki krańcowe, których wydzielenie w języku SQL okazało się być skomplikowane zrezygnowałem z implementacji takiej funkcji.

## Wyzwalacze
1. Walidator danych właścicieli <br>
![image](https://user-images.githubusercontent.com/68378289/219685780-b02257bf-3fc9-4454-bbd3-3851d1b2d079.png)
2. Automatyczne zamykanie ofert usuniętego właściciela z odpowiednim powodem == 'OD' (Offer Deleted) <br>
![image](https://user-images.githubusercontent.com/68378289/219686252-d3d91dd4-97d3-4bf8-9008-fa3afdf93df2.png)
3. Blokowanie usuwania lokalizacji dla których istnieją w bazie domy <br>
![image](https://user-images.githubusercontent.com/68378289/219686355-339c9764-988e-4381-9d7d-a9a2e2b54461.png)
4. Automatyczne dodawanie zmiany ceny dla nowej oferty do tabeli [Price Changes] <br>
![image](https://user-images.githubusercontent.com/68378289/219686597-01d3b666-2923-41d5-b53a-3748761fa6e9.png)
5. Blokowanie retroaktywnych aktualizacji tabeli [Price Changes] <br>
![image](https://user-images.githubusercontent.com/68378289/219687024-9fa2d473-18d4-4d44-a37d-0a44a4e16d61.png)

