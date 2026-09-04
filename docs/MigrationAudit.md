# Audyt migracji kodu

## Stan eksportu

- Źródło: `Weeks End.rbxl`
- Odzyskane skrypty: 31 z 31
- `Script`: 11
- `LocalScript`: 8
- `ModuleScript`: 12
- Puste pliki: 0
- Zgodność początkowego eksportu `raw-scripts` → `src`: 31/31 identycznych sum
  SHA-256 przed rozpoczęciem optymalizacji
- Walidacja projektu: `rojo build default.project.json` zakończona powodzeniem

## Zachowana hierarchia

| Miejsce Roblox | Źródło Rojo |
| --- | --- |
| `ServerScriptService` | `src/Server` |
| `StarterPlayer/StarterPlayerScripts` | `src/Client` |
| `ReplicatedStorage/Modules` | `src/Shared/Modules` |
| `ReplicatedStorage/Shared/Hello` | `src/Shared/Hello.luau` |
| `ReplicatedStorage/HollowMimicAnimator` | `src/ReplicatedStorage` |
| `ServerStorage/MonsterRigs` | `src/ServerStorage/MonsterRigs` |

Położenie skryptów zależnych od `script.Parent` zostało zachowane. Dotyczy to
między innymi `RoundState` oraz modułów korzystających z `RigBuilder`.

## Znalezione elementy prototypowe

Poniższe pliki zawierają wyłącznie pojedynczy `print` i nie implementują jeszcze
mechaniki:

- `src/Server/RoundService.server.luau`
- `src/Server/EvidenceService.server.luau`
- `src/Server/ProximityChatService.server.luau`
- `src/Server/Server.server.luau`
- `src/Client/Client.client.luau`
- `src/Client/DetectiveBoardUI.client.luau`
- `src/Client/ProximityChatUI.client.luau`

`src/Shared/Hello.luau` jest również modułem demonstracyjnym. Warto usuwać te
pliki dopiero po potwierdzeniu, że nie są celowymi punktami startowymi przyszłych
systemów.

## Mała optymalizacja po eksporcie

- `NPCService` przechowuje aktywne NPC jako zbiór, dzięki czemu usuwanie po
  śmierci nie skanuje całej tablicy.
- Parametry `PathfindingService:CreatePath` są współdzielone zamiast tworzone od
  nowa dla każdej trasy.
- `PlayerAppearance` oczekuje bezpośrednio na `Humanoid` zamiast zawsze
  zatrzymywać obsługę postaci na jedną sekundę.
- Animator Hollow Mimic nie tworzy nowego `Vector3` w każdej klatce i ogranicza
  współczynnik interpolacji do poprawnego zakresu.
- Kolor przycisku transformacji jest ustawiany raz na cooldown, a nie co sekundę.

## Ryzyka do sprawdzenia przed publikacją

1. `MonsterTransformService` obsługuje żądanie klienta przez `OnServerEvent`.
   Serwer sprawdza rolę i stan rundy, ale mechanikę należy jeszcze przetestować
   pod kątem limitowania częstotliwości wywołań.
2. Systemy miasta oczekują istniejących obiektów `ReplicatedStorage.Remotes`,
   elementów mapy oraz spawnów NPC. Są one zachowane w oryginalnym `.rbxl`, lecz
   nie są obecnie generowane przez kod Rojo.
3. `HollowMimicAnimator` jest szablonem `LocalScript` przechowywanym bezpośrednio
   w `ReplicatedStorage` i jest klonowany do modelu postaci. Nie należy przenosić
   go do `StarterPlayerScripts`.
4. Przed większą refaktoryzacją potrzebne są testy w Studio: uruchomienie rundy,
   przydział ról, transformacja potwora, interakcje komisariatu i sklepu oraz
   odradzanie NPC.

## Następny etap

Po teście zgodności w Studio można rozdzielić duże skrypty na serwisy i moduły,
dodać wspólny bootstrap/rejestr serwisów, walidację RemoteEventów, logowanie oraz
testy jednostkowe. Surowy eksport powinien pozostać niezmieniony jako materiał
porównawczy podczas tej refaktoryzacji.
