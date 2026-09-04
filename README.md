# Weeks End

Kod gry został wyciągnięty z `Weeks End.rbxl` do plików Luau i podłączony przez
[Rojo](https://rojo.space/). Oryginalny plik miejsca pozostaje źródłem mapy,
interfejsów, modeli i pozostałych instancji, których ten projekt nie nadpisuje.

## Struktura

- `src/Server` — skrypty i moduły z `ServerScriptService`
- `src/Client` — skrypty z `StarterPlayerScripts`
- `src/Shared` — moduły z `ReplicatedStorage`
- `src/ReplicatedStorage` — skrypty przechowywane bezpośrednio w `ReplicatedStorage`
- `src/ServerStorage` — serwerowe moduły modeli potworów
- `raw-scripts` — niezmieniony eksport referencyjny wraz z manifestem

## Praca w Roblox Studio

1. Otwórz `Weeks End.rbxl` w Roblox Studio.
2. W katalogu projektu uruchom `rojo serve default.project.json`.
3. Połącz plugin Rojo w Studio z uruchomionym serwerem.

Konfiguracja ma włączone zachowywanie nieznanych instancji. Synchronizacja kodu
nie powinna usuwać mapy, modeli, RemoteEventów ani elementów UI istniejących w
oryginalnym miejscu.

## Kontrola eksportu

`raw-scripts/manifest.json` zapisuje pierwotną ścieżkę i klasę każdego z 31
odzyskanych skryptów. Pliki w `src` są na razie wierną kopią kodu źródłowego;
refaktoryzację należy prowadzić już w `src`, pozostawiając `raw-scripts` jako
punkt odniesienia.
