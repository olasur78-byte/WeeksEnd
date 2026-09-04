# Integracja mapy z systemami kodowymi

Mechaniki nie wymagają konkretnych modeli mapy, ale części interakcyjne muszą
otrzymać poniższe tagi lub atrybuty w Roblox Studio.

## Tagi CollectionService

| Tag | Obiekt | Znaczenie |
| --- | --- | --- |
| `KidnapHouse` | Model domu | Dom losowany wspólnie dla porywacza i ofiary |
| `RoundSpawn` | BasePart | Publiczny spawn detektywów |
| `BasementZone` | Niewidoczny BasePart | Strefa zakazana policji i chroniona przed podglądaniem kamerą |
| `PoliceStationZone` | Niewidoczny BasePart | Strefa zakazana porywaczowi i cywilom |

Model domu powinien zawierać `KidnapSpawn` albo `BasementSpawn`. Jeśli nie ma
tagów domów, system próbuje znaleźć modele zawierające `House` w nazwie.

## Atrybuty ProximityPrompt lub jego części

| Atrybut | Wartość | Efekt |
| --- | --- | --- |
| `VictimTask` | `LockpickCraft` | Wytworzenie wytrycha |
| `VictimTask` | `DoorPuzzle` | Zagadka drzwi |
| `VictimTask` | `RoomPuzzle` | Trwała zagadka pokoju |
| `VictimTask` | `FinalDoor` | Ostatnie otwarcie drzwi |
| `SupplyType` | `Food` / `Water` | Zużycie zapasu ofiary |
| `EvidenceKind` | `Visual` / `Witness` / `Physical` | Dowód zawężający typ potwora |
| `MonsterActivity` | `Groceries` / `Pharmacy` / `PoliceQuestioning` | Dzienne zadanie kamuflażu |

Kamery zachowują istniejące atrybuty `EvidenceType = CCTV`, `CameraId` i
`Location`. Działają tylko w dzień. Wybranie pozycji na monitorze przełącza
kamerę gracza na zapisany `CFrame`; zamknięcie monitora przywraca zwykłą kamerę.

## Warunki zwycięstwa policji

Ofiara musi ukończyć wszystkie cztery etapy, opuścić dom i wejść do strefy
`PoliceStationZone`. Detektyw musi następnie wskazać poprawny typ potwora w panelu
widocznym po lewej stronie. Samo uratowanie ofiary nie kończy rundy.
