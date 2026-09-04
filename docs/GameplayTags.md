# Integracja mapy z systemami kodowymi

Mechaniki nie wymagają konkretnych modeli mapy, ale części interakcyjne muszą
otrzymać poniższe tagi lub atrybuty w Roblox Studio.

Plik `Weeks End.tagged.rbxl` ma już oznaczone wszystkie pasujące obiekty wykryte
w obecnej mapie. Poniższa tabela jest również kontraktem dla nowych obiektów.

## Tagi CollectionService

| Tag | Obiekt | Znaczenie |
| --- | --- | --- |
| `KidnapHouse` | Model domu | Dom losowany wspólnie dla porywacza i ofiary |
| `RoundSpawn` | BasePart | Publiczny spawn detektywów |
| `BasementZone` | Model domu lub BasePart strefy | Strefa zakazana policji i chroniona przed podglądaniem kamerą |
| `PoliceStationZone` | Folder/model komisariatu albo BasePart | Strefa zakazana porywaczowi i cywilom |
| `NPCWaypoint` | BasePart na chodniku | Opcjonalny, bezpieczny cel spacerów NPC |
| `NPCStreet` | BasePart ulicy lub chodnika | Powierzchnia losowego spawnu i spacerów NPC; zalecany tag dla pewnego wykrywania |

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
