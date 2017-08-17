//
//  UpdateApptTVC.swift
//  Appt
//
//  Created by Agustin Mendoza Romo on 8/6/17.
//  Copyright © 2017 AgustinMendoza. All rights reserved.
//

import UIKit
import CoreData
import JTAppleCalendar

class UpdateApptTVC: UITableViewController, AppointmentTVC {
  
  
  
  var selectedTimeSlot: Date?
  var appointmentsOfTheDay: [Appointment]?
  var patient: Patient? {
    didSet {
      if patient?.fullName != nil {
        patientLabel.text = patient?.fullName
      }
    }
  }
  
  var appointment: Appointment?
  let formatter = DateFormatter()
  var appointmentLoaded: Bool! 
  
  let segueSelectPatient = "SegueSelectPatientsTVC"
  
  let persistentContainer = CoreDataStore.instance.persistentContainer
  var managedObjectContext: NSManagedObjectContext?
  
  var datePickerHidden = false
  var calendarViewHidden = false
  
  // Calendar Color
  let outsideMonthColor = UIColor.lightGray
  let monthColor = UIColor.darkGray
  let selectedMonthColor = UIColor.white
  let currentDateSelectedViewColor = UIColor.black
  
  
  // Load Appointments For given Date
  lazy var fetchedResultsController: NSFetchedResultsController<Appointment> = {
    let fetchRequest: NSFetchRequest<Appointment> = Appointment.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
    if let selectedDate = calendarView.selectedDates.first {
      fetchRequest.predicate = getPredicate(for: selectedDate )
    }
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
  }()
  
  
  
  @IBOutlet var calendarView: JTAppleCalendarView!
  @IBOutlet var monthLabel: UILabel!
  @IBOutlet var yearLabel: UILabel!
  
  @IBOutlet weak var timeSlotLabel: UILabel!
  @IBOutlet weak var patientLabel: UILabel!
  @IBOutlet weak var noteTextView: UITextView!
  @IBOutlet weak var costTextField: UITextField!
  @IBOutlet weak var dateDetailLabel: UILabel!
//  @IBOutlet weak var datePicker: UIDatePicker!
  
  @IBAction func cancelButton(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func confirmAppointment(_ sender: UIBarButtonItem) {
    confirmAppointment()
  }

  
  override func viewDidLoad() {
    super.viewDidLoad()
    noLargeTitles()
    setupCalendarView()
    fetchAppointmentsForDay()
    setupKeyboardNotification()
    setTextFieldDelegates()
    setTextViewDelegates()
    setDoneOnKeyboard()
    
    calendarView.visibleDates{ (visibleDates) in
      self.setupViewsFromCalendar(from: visibleDates)
    }
    
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    if appointmentLoaded {
      loadAppointment()
      appointmentLoaded = false
    }
    if selectedTimeSlot != nil {
      timeSlotLabel.text = selectedTimeSlot?.toHourMinuteString()
    }
    
  }
  
  func loadAppointment() {
    if let appointment = appointment {
      if let date = appointment.date,
        let patient = appointment.patient,
        let cost = appointment.cost,
        let note = appointment.note {
        
        let dates: [Date] = [date]
        calendarView.scrollToDate(date, animateScroll: false)
        calendarView.selectDates( dates )
        //        calendarView.date
        //        dateDetailLabel.text = dateFormatter(date: date)
        patientLabel.text = patient.fullName
        self.patient = patient
        costTextField.text = cost
        noteTextView.text = note
        //        datePicker.date = date
        
        print("Appointment date: \(String(describing: dates.first))")
        //        print("CalendarView date: \(calendarView.selectDates)")
      }
    }
  }
  
  
  
  func confirmAppointment() {
    guard let appointment = appointment else {
      return
    }
    appointment.patient = patient
    appointment.date = selectedTimeSlot
    appointment.note = noteTextView.text
    appointment.cost = costTextField.text
    appointment.dateModified = Date()
    
    CoreDataStore.instance.save()
    dismiss(animated: true, completion: nil)
  }
  
  
  func noLargeTitles(){
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
      tableView.dragDelegate = self as? UITableViewDragDelegate
    }
  }
  
  func setupKeyboardNotification() {
    NotificationCenter.default.addObserver(self, selector: #selector(NewApptTableViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(NewApptTableViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
  }
  
  @objc func keyboardWillShow(notification: NSNotification) {
    if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
      tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + 20, 0)
    }
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
    UIView.animate(withDuration: 0.2, animations: {
      // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
      self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    })
  }
  
  
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 1
    } else {
      return 22
    }
  }
}


extension UpdateApptTVC {
  func toggleCalendarView() {
    calendarViewHidden = !calendarViewHidden
    
    tableView.beginUpdates()
    tableView.endUpdates()
  }
  
  func updateDateDetailLabel(date: Date){
    formatter.dateFormat = "MMMM dd, yyyy"
    dateDetailLabel.text = formatter.string(from: date)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 && indexPath.row == 0 {
      toggleCalendarView()
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if calendarViewHidden && indexPath.section == 0 && indexPath.row == 1 {
      return 0
    } else {
      return super.tableView(tableView, heightForRowAt: indexPath)
    }
  }
}


// Date picker
extension UpdateApptTVC {
  @IBAction func datePickerValue(_ sender: UIDatePicker) {
    datePickerChanged()
  }
  
  // Run datePickerChanged() in viewDidLoad() to display selected date in Label
  func datePickerChanged() {
    //    dateDetailLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
  }
  
  func toggleDatePicker() {
    datePickerHidden = !datePickerHidden
    
    tableView.beginUpdates()
    tableView.endUpdates()
  }
  
  // Toggle DatePicker
  
  //  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  //    if indexPath.section == 0 && indexPath.row == 0 {
  //      toggleDatePicker()
  //    }
  //  }
  //
  //  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
  //    // Use the datePicker row. The one below is from a previous iteration
  //    if datePickerHidden && indexPath.section == 0 && indexPath.row == 1 {
  //      return 0
  //    } else {
  //      return super.tableView(tableView, heightForRowAt: indexPath)
  //    }
  //  }
}


extension UpdateApptTVC {
  func handleCellSelected(view: JTAppleCell?, cellState: CellState) {
    guard let validCell = view as? CalendarDayCell else { return }
    if validCell.isSelected {
      validCell.selectedView.isHidden = false
    } else {
      validCell.selectedView.isHidden = true
    }
  }
  
  func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
    guard let validCell = view as? CalendarDayCell else {
      return
    }
    
    if validCell.isSelected {
      validCell.dateLabel.textColor = selectedMonthColor
    } else {
      if cellState.dateBelongsTo == .thisMonth {
        validCell.dateLabel.textColor = monthColor
      } else {
        validCell.dateLabel.textColor = outsideMonthColor
      }
    }
  }
  
  func setupCalendarView() {
    // Setup Calendar Spacing
    calendarView.minimumLineSpacing = 0
    calendarView.minimumInteritemSpacing = 0
    
    // Setup Labels
    calendarView.visibleDates{ (visibleDates) in
      self.setupViewsFromCalendar(from: visibleDates)
    }
  }
  
  func setupViewsFromCalendar(from visibleDates: DateSegmentInfo ) {
    guard let date = visibleDates.monthDates.first?.date else { return }
    
    formatter.dateFormat = "yyyy"
    yearLabel.text = formatter.string(from: date)
    
    formatter.dateFormat = "MMMM"
    monthLabel.text = formatter.string(from: date)
  }
  
  //  func calendarViewDateChanged() {
  //    guard let calendarDate = calendarView.selectedDates.first else { return }
  //    dateDetailLabel.text = DateFormatter.localizedString(from: calendarDate, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
  //  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let calendarDate = calendarView.selectedDates.first
    if segue.identifier == "segueTimeSlotsFromUpdate" {
      let destinationVC = segue.destination as! TimeSlotsCVC
      destinationVC.appointmentDate = calendarDate
      if let currentAppointments = appointmentsOfTheDay {
        destinationVC.currentAppointments = currentAppointments
      }
    }
  }
}


extension UpdateApptTVC: JTAppleCalendarViewDataSource {
  
  func loadAppointmentsForDate(date: Date){
    var calendar = Calendar.current
    calendar.timeZone = NSTimeZone.local
    
    let dateFrom = calendar.startOfDay(for: date)
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateFrom)
    components.day! += 1
    let dateTo = calendar.date(from: components)
    
    let datePredicate = NSPredicate(format: "(%@ <= date) AND (date < %@)", argumentArray: [dateFrom, dateTo])
    if let fetchedObjects = fetchedResultsController.fetchedObjects {
      appointmentsOfTheDay = fetchedObjects.filter({ return datePredicate.evaluate(with: $0) })
    }
    
    if appointmentsOfTheDay != nil {
      for appointment in appointmentsOfTheDay! {
        print("Appointment date is: \(String(describing: appointment.date))")
      }
    } else {
      print("Appointment is empty")
    }
    //    tableView.reloadData()
  }
  
  func getPredicate(for date: Date) -> NSPredicate {
    var calendar = Calendar.current
    calendar.timeZone = NSTimeZone.local
    
    let dateFrom = calendar.startOfDay(for: date)
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateFrom)
    components.day! += 1
    let dateTo = calendar.date(from: components)
    let datePredicate = NSPredicate(format: "(%@ <= date) AND (date < %@)", argumentArray: [dateFrom, dateTo as Any])
    
    return datePredicate
  }
  
  func fetchAppointmentsForDay() {
    do {
      try self.fetchedResultsController.performFetch()
      print("AppointmentForDay Fetch Successful")
    } catch {
      let fetchError = error as NSError
      print("Unable to Perform AppointmentForDay Fetch Request")
      print("\(fetchError), \(fetchError.localizedDescription)")
    }
  }
  
  
  func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
    formatter.dateFormat = "yyyy MM dd"
    formatter.timeZone = Calendar.current.timeZone
    formatter.locale = Calendar.current.locale
    
    var parameters: ConfigurationParameters
    var startDate = Date()
    var endDate = Date()
    if let calendarStartDate = formatter.date(from: "2017 01 01"),
      let calendarEndndDate = formatter.date(from: "2017 12 31") {
      startDate = calendarStartDate
      endDate = calendarEndndDate
    }
    parameters = ConfigurationParameters(startDate: startDate, endDate: endDate)
    
    return parameters
  }
}


extension UpdateApptTVC: JTAppleCalendarViewDelegate {
  // Display Cell
  func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
    let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as! CalendarDayCell
    cell.dateLabel.text = cellState.text
    
    handleCellSelected(view: cell, cellState: cellState)
    handleCellTextColor(view: cell, cellState: cellState)
    
    return cell
  }
  
  func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
    handleCellSelected(view: cell, cellState: cellState)
    handleCellTextColor(view: cell, cellState: cellState)
    
    updateDateDetailLabel(date: date)
    loadAppointmentsForDate(date: date)
    //    calendarViewDateChanged()
  }
  
  func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
    handleCellSelected(view: cell, cellState: cellState)
    handleCellTextColor(view: cell, cellState: cellState)
  }
  
  func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
    setupViewsFromCalendar(from: visibleDates)
  }
  
}


extension UpdateApptTVC: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
    
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch (type) {
    case .insert:
      if let indexPath = newIndexPath {
        print("Appt Added")
        tableView.insertRows(at: [indexPath], with: .fade)
      }
      break;
    case .delete:
      if let indexPath = indexPath {
        tableView.deleteRows(at: [indexPath], with: .fade)
      }
      break;
    case .update:
      if let indexPath = indexPath {
        print("Appt Changed and updated")
        tableView.reloadRows(at: [indexPath], with: .fade)
      }
    default:
      print("...")
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
  }
  
}
