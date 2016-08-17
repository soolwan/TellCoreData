//
//  ViewController.swift
//  TellCoreData
//
//  Created by Sean Coleman on 8/17/16.
//  Copyright © 2016 Sean Coleman. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ViewController: UIViewController, SpeechServiceDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        initiateFetchedResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        speechService?.delegate = self

        updateForSpeechState(speechState: .NoPermission)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        speechService?.setupSpeech()
    }

    // MARK: - ViewController

    // MARK: Internal

    var colorService: ColorService!
    var speechService: SpeechService!
    var coreDataManager: CoreDataManager!

    // MARK: Private

    private var colors: [Colour] = []
    private var fetchedResultsController: NSFetchedResultsController<Colour>?

    private func initiateFetchedResultsController() {
        if let context = coreDataManager?.container.viewContext, let fetchRequest = colorService?.getColorsFetchRequest() {
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        }

        fetchedResultsController?.delegate = self

        do {
            try fetchedResultsController?.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }

    private func displayColorForColour(colour: Colour) -> UIColor {
        let red = CGFloat(colour.red / 255.0)
        let green = CGFloat(colour.green / 255.0)
        let blue = CGFloat(colour.blue / 255.0)
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    private func updateForSpeechState(speechState: SpeechState) {
        switch speechState {
        case .Available:
            recordButton.isEnabled = true
            recordButton.setTitle("Record", for: [])
        case .NoPermission, .NotAvailable:
            recordButton.isEnabled = false
            recordButton.setTitle("Record", for: [])
        case .Recording:
            recordButton.isEnabled = true
            recordButton.setTitle("Stop Recording", for: [])
        case .Stopping:
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: [])
        }
    }

    // MARK - SpeechServiceDelegate

    func speechStateDidChange(speechState: SpeechState) {
        updateForSpeechState(speechState: speechState)
    }

    func completeWithText(text: String) {
        print(text)

        if let colors = colorService.colorsIn(text: text), !colors.isEmpty {
            colorService.insertColors(colors: colors)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections.count
        }
        
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)

        if let color = fetchedResultsController?.object(at: indexPath) {
            cell.backgroundColor = displayColorForColour(colour: color)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        default:
            return
        }
    }

    // MARK: - Actions

    @IBAction func recordButtonPressed(_ sender: UIButton) {
        speechService?.startStop()
    }

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView!
    @IBOutlet var recordButton: UIButton!
}
