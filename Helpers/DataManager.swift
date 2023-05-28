//
//  DataManager.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/05/2023.
//

import Foundation

class DataManager {
    
    private init() {}
    
    static func getDocumentsDirectory() -> URL {
        let files = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return files[0]
    }
    
    /**
     Given some filepath, attempt to decode the contents.
     */
    static func decodeDocumentJson<T: Decodable>(url: URL) -> T {
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
            print("Error saving dictionary to disk.")
        }
    }
    
    /**
     Assuming the data has been retrieved, this function decodes recieved payloads.
     */
    static func decodeJson<T: Decodable>(data: Data) -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(T.self): \n\(error)")
        }
    }
    
}
