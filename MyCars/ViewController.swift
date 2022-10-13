//
//  ViewController.swift
//  MyCars
//
//  Created by Rail on 06.04.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    //    Библиотека данных в CoreData. Контекст, который мы получили из SceneDelegate
    var context: NSManagedObjectContext!
    //    Создаём переменную car для обращения к ней через кнопки чтобы внести изменения
    var car: Car!
    
    //    Форматируем дату до необходимого вида отображения для lastTimeStartedlable
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    //    Сегмент контрол для выбора автомобиля
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentedControl()
            
            //            Явно указываем на выделенный сегмент ввиде белого цвета
            segmentedControl.selectedSegmentTintColor = .white
            //            Создаём атрибут текста Белым
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            //            Создаём атрибут текста Чёрным
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            //            В обычном состоянии текст всех сегментов будет белым
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            //            Когда сегмент выделен, цвет текста в нём будет всегда чёрным
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
            
        }
    }
    //    Лейбл с отметкой
    @IBOutlet weak var markLable: UILabel!
    //    Лейбл с моделью авто
    @IBOutlet weak var modelLable: UILabel!
    //    Фото автомобиля
    @IBOutlet weak var carImageView: UIImageView!
    //    Последний запуск
    @IBOutlet weak var lastTimeStartedlable: UILabel!
    //    Кол-во поездок
    @IBOutlet weak var numberOfTripsLable: UILabel!
    //    Лейбл с рейтингом авто
    @IBOutlet weak var ratingLable: UILabel!
    //    Лучший выбраный авто
    @IBOutlet weak var myChoiceImageView: UIImageView!
    //    Кнопка запуска двигателя
    @IBOutlet weak var startEngineButton: UIButton!
    //    Кнопка для указания рейтинга авто
    @IBOutlet weak var rateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getDataFromFile()
        //        Настраиваем вид кнопок
        startEngineButton.layer.cornerRadius = 7
        rateButton.layer.cornerRadius = 7
        
        updateSegmentedControl()
    }
    
    //    Обновляем данные по сегментед контроллу
    private func updateSegmentedControl() {
        //        Получаем данные
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        //        Марка авто будет именно то, что указано в заголовке SegmentedControl
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        //        Сравниваем данные data.plist с segmentedControl по марке автомобиля
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        //        Получаем данные
        do {
            let results = try context.fetch(fetchRequest)
            //            Наш выбраный автомобиль
            car = results.first
            //            Вызываем метод отображения данных на экране
            insertDateFrom(selectedCar: car!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    //    Раскидываем наши данные, которые мы получили из CoreData по объектам отображаемым в симуляторе
    private func insertDateFrom(selectedCar car: Car) {
        carImageView.image = UIImage(data: car.imageData!)
        markLable.text = car.mark
        modelLable.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLable.text = "Rating: \(car.rating) / 10"
        numberOfTripsLable.text = "Number of trips: \(car.timesDriven)"
        
        lastTimeStartedlable.text = "Last time started: \(dateFormatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    //    Метод будет срабатывать при загрузке приложения
    func getDataFromFile() {
        ///       При загрузке приложения проверяем имеется ли какая-то информация в CoreData или нет. Если имеется, значит приложения уже загружали или используется или вносили какие-то свои данные. Таким образом не придётся подгружть эти данные ещё раз. По хорошему это нужно делать через userDefoults, но мы пошли другим путём в качестве тренировки.
        //        Получаем все записи типа car, которые у нас имеются в базе данных. Если нет, то код выполняем, если данные имеются, то не выполняем
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        //         Получаем записи которые не равны nil, то есть данные имеются. Мы можем фильтровать данные, которые получаем 
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
            print("Is Data there already?")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        //        Проверяем сколько записей имеется в переменной records. Если записей 0, то прекращаем работу
        guard records == 0 else { return }
        
        
        /// Первое что необходимо сделать !!!
        //        Получаем путь к нашим данным из файла data.plist ввиде массива
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              //        Извлекаем массив словарей из полученного пути pathToFile
              let dataArray = NSArray(contentsOfFile: pathToFile)  else { return }
        //        Проводим итерацию по этому маcсиву, берём данные и помещаем в CoreData
        for dictionary in dataArray {
            //            Создаём entity (объект или сущность) для того, чтобы можно было создать объект для хранения внутри нашей базы данных
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            //            Создаём объект, чтобы перенести данные
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            //            Достаём данные (распаковываем словарь)
            let carDicionary = dictionary as! [String : AnyObject]
            car.mark = carDicionary["mark"] as? String
            car.model = carDicionary["model"] as? String
            car.rating = carDicionary["rating"] as! Double
            car.lastStarted = carDicionary["lastStarted"] as? Date
            car.timesDriven = carDicionary["timesDriven"] as! Int16
            car.myChoice = carDicionary["myChoice"] as! Bool
            
            let imageName = carDicionary["imageName"] as? String
            //            Конвертируем в Имедж
            let image = UIImage(named: imageName!)
            //            Конвертируем в Дата
            let imageData = image!.pngData()
            //            Извлекаем изображение
            car.imageData = imageData
            //            Извлкаем цвет
            if let colorDictionary = carDicionary["tintColor"] as? [String : Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
    }
    
    //    Вспомогательная функция для извлечения цвета авто в виде массива
    private func getColor(colorDictionary: [String : Float]) -> UIColor {
        guard let red = colorDictionary["red"],
              let green = colorDictionary["green"],
              let blue = colorDictionary["blue"] else { return UIColor()}
        return UIColor(red: CGFloat(red / 255), green: CGFloat( green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
    }
    
    //    Метод, который добавляет картинку (медаль), если авто достигает нужного рейтинга
    private func updateImageChousenCar() {
        //        Берём рейтинг автомобиля
        let choiceCar = self.car.rating
        print(choiceCar)
        //        Если рейтинг более 9,
        if 9.0 ... 10.0 ~= choiceCar {
            //            то myChoice становится труу
            car.myChoice = true
            //            и добавляется медаль снизу Сегментед Контрола
            myChoiceImageView.image = #imageLiteral(resourceName: "Medal")
            
            do {
                //                Сохраняем данные в CoreData
                try context.save()
                //                и нашем data.plist
                insertDateFrom(selectedCar: car)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            //            Вслучае если рейтинг не достиг авто, картинка убирается
            myChoiceImageView.image = nil
        }
    }
    
    //    Сегмент контрол
    @IBAction func segmentedCntrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
        //        Установить медаль на автомобиль в случае хорошего рейтинга
        updateImageChousenCar()
    }
    
    //    Кнопка начала поездки
    @IBAction func startEnginePressed(_ sender: UIButton) {
        //        Добавляем кол-во поездок
        car.timesDriven += 1
        //        Обновляем дату последней поездки
        car.lastStarted = Date()
        
        do {
            //            Сохраняем данные в CoreDate
            try context.save()
            //            Вставляем обновления в библиотеку данных data.plist
            insertDateFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    //    Кнопка указания рейтинга авто
    @IBAction func reteItPressed(_ sender: UIButton) {
        //        Создаём всплывающее окно Алерт Контроллера для ввода рейтинга автомобиля
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            //            Достаём текст из текстового поля и всталяем в качество нового значения для рейтинга нашего автомобиля
            if let text = alertController.textFields?.first?.text {
                //                ОБновляем рейтинг
                self.update(rating: (text as NSString).doubleValue)
                //                Установить медаль на автомобиль в случае хорошего рейтинга
                self.updateImageChousenCar()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        //        Добавляем в Алерт Контроллер текствое поле, также ввод будет осуществляться только с помощью числовых значений
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
        
    }
    
    //    Обновление данных рейтинга авто
    private func update(rating: Double) {
        //        Присваиваем новое значение рейтингу
        car.rating = rating
        //        Сохраняем эти изменения
        do {
            //            Если получилось сохранить context
            try context.save()
            //            то сохраняем текущее значение в методе отображения данных на экране
            insertDateFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
}

