//
//  ColorService.swift
//  TellCoreData
//
//  Created by Sean Coleman on 8/17/16.
//  Copyright © 2016 Sean Coleman. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ColorService {

    // MARK: - Lifetime

    init(coreDataManager: CoreDataManager?) {
        self.coreDataManager = coreDataManager
    }

    // MARK: - ColorService

    // MARK: Internal

    let coreDataManager: CoreDataManager?

    func getColorsFetchRequest() -> NSFetchRequest<Colour> {
        let request: NSFetchRequest<Colour> = Colour.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        return request
    }

    func insertColors(colors: [String]) {
        coreDataManager?.container.performBackgroundTask() { [unowned self] (context) in
            for color in colors {
                let components = self.componentsForColor(color: color)

                let color = Colour(context: context)
                color.red = components.red
                color.green = components.green
                color.blue = components.blue
                color.createdAt = NSDate()
            }

            do {
                try context.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
        }
    }

    func colorsIn(text: String) -> [String]? {
        if let regex = makeRegexWithColors(colors: supportedColors) {
            let colorMatches = matchesForRegex(regex: regex, inText: text.lowercased())
            return colorMatches
        }

        return nil
    }

    // MARK: Private

    private let supportedColors = ["red", "blue", "green", "orange", "purple", "pink", "yellow", "black", "white"]

    private func componentsForColor(color: String) -> (red: Float, green: Float, blue: Float) {
        switch color.lowercased() {
        case "red":    return (255.0, 0.0, 0.0)
        case "green":  return (0.0, 255.0, 0.0)
        case "blue":   return (0.0, 0.0, 255.0)
        case "orange": return (255.0, 128.0, 0.0)
        case "purple": return (76.0, 0.0, 153.0)
        case "pink":   return (255.0, 51.0, 255.0)
        case "yellow": return (255.0, 255.0, 0.0)
        case "black":  return (0.0, 0.0, 0.0)
        case "white":  return (255.0, 255.0, 255.0)
        default:       return (0.0, 0.0, 0.0)
        }
    }

    private func makeRegexWithColors(colors: [String]?) -> NSRegularExpression? {
        guard let colors = colors else { return nil }

        let pattern = "(\(colors.joined(separator: "|")))"

        do {
            return try NSRegularExpression(pattern: pattern, options: [])
        } catch _ as NSError {
            print("Error making regex with tags: \(colors)")
            return nil
        }
    }

    private func matchesForRegex(regex: NSRegularExpression, inText text: String) -> [String] {
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        return results.map { nsString.substring(with: $0.range) }
    }
}
