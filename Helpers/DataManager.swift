//
//  DataManager.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/05/2023.
//

import Foundation

struct DataManager {
    
    private init() {}
    
    static func getDocumentsDirectory() -> URL {
        let files = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return files[0]
    }
    
    /**
     Given some filepath, attempt to decode the contents.
     */
    static func decodeDocumentJson<T: Decodable>(url: URL) -> T? {
        do {
            let contents = try Data(contentsOf: url)
            return decodeJson(data: contents)
        } catch {
            fatalError("Encountered an error while decoding a document.")
        }
    }
    
    /**
     Given some data as a dictionary, save the data as JSON to a given filepath.
     */
    static func saveAsJsonRepresentation(path: URL, data: Encodable) {
        do {
            let encoder = JSONEncoder()
            let jsonString = try encoder.encode(data)
            try jsonString.write(to: path)
        } catch {
            print("Error saving JSON to disk.")
        }
    }
    
    /**
     Assuming the data has been retrieved, this function decodes recieved payloads.
     */
    static func decodeJson<T: Decodable>(data: Data) -> T? {
        do {
            let decoder = JSONDecoder()
            print("Trying decode of \(data) for \(T.self)")
            let decoded: T? = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            print("Couldn't parse \(T.self): \(String(describing: error))")
            return nil
        }
    }
    
    struct englishHolidays {
        
        private init() {}
        
        static let cachePath = DataManager.getDocumentsDirectory().appendingPathComponent("UKHolidays", conformingTo: .json)
        
        static func getDivisionDataFromDisk() -> HolidayDivision? {
            return DataManager.decodeDocumentJson(url: cachePath)
        }
        
        static func downloadAndSaveToDisk() async {
            let data: HolidayDivision? = await APIHandler.shared.getEnglishHolidays()
            saveDivisionToDisk(division: data)
        }
        
        private static func saveDivisionToDisk(division: HolidayDivision?) {
            DataManager.saveAsJsonRepresentation(path: englishHolidays.cachePath, data: division)
        }
        
    }
    
}
