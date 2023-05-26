# Написание тестов в ASDKSampleTests

### ⛑️ Начало работы
Для запуска и настройки проекта, перед написанием снепшот тестов следует вызвать команду
`make snapshot_testing` которая подготовит среду для работы. Обрати внимание не пушь изменения `Podfile.lock` файла чтобы не сломать сборку на **CI**.

### 🛠️ Snapshot-testing 
Для снепшот тестирования используем библиотеку от [pointfree](https://github.com/pointfreeco/swift-snapshot-testing)
>Она позволяет сравнивать многие типы объектов.
>Для `UIView` + `UIViewController` реализовано снепшот тестирование через сравнение скриншотов. 

Если тестируешь `UIView` достаточно указать:

```swift
let view = UIView()
// сконфигурировать вью
view.configure()
// задать свой размер если нет из коробки
view.frame.size = CGSize(width: 100, height: 100) 

// Можно не указывать traits но если указал то сделай и для темной темы
assertSnapshot(
    matching: view, 
    as: .image(traits: .init(userInterfaceStyle: .light)), 
    // флаг record указываем при первом прогоне 
    // потом видим что появился скриншот, если все ок
    // меняем record на false [не удаляем record для удобства перезаписи]
    record: false
)
```

> **✋ Warning ✋**
>
> Делаем снепшоты и запускаем тесты на симуляторе **iPhone 13 - iOS 16.1** *Xcode 14.1*
>
> Для снепшотов `UIViewController` важно на всех тестах указывать версию симулятора **iPhone 13**
```swift
assertSnapshot(matching: vc, as: .image(on: .iPhone13))
```

> Snapshots must be compared using the exact same simulator that originally took the reference to avoid discrepancies between images.

### ✅ Тест планы
В проекте есть 2 тест-плана
 - `ASDKSampleTests-RU.xctestplan`
   - Сюда помещаем тесты с локализацией **RU**
- `ASDKSampleTests-EN.xctestplan`
  - Сюда помещаем тесты с локализацией **EN**

>Важно новые тесты надо **самостоятельно** добавлять в тест план. 

Также есть 2 схемы `ASDKSampleTests-EN` и `ASDKSampleTests-RU`
Это нужно для запуска симулятора с нужным языком. В рантайме менять налету язык без хаков к сожалению нельзя.

### 🤝 Конвенции
1. Сохраняем текущую структуру папок при создании тестов
2. Тест кейс называем с префиксом в конце `TestsRU` || `TestsEN`
3. Руками выключаем из тестпланов новые тесты (там где нужно). Так как новые тесты попадают сразу в 2 тест плана. 