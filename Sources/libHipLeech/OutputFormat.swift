//
//  File.swift
//  
//
//  Created by Thomas Mellenthin (Privat) on 21.02.20.
//

import Foundation

public enum OutputFormat: String, CaseIterable, RawRepresentable {
    case ascii = "ascii"
    case markdown = "markdown"
    case json = "json"
    /*
    init?(_ value: String) {
        switch value {
        case "ascii": self = .ascii
        case "markdown": self = .markdown
        case "json": self = .json
        default:
            return nil
        }
    }
 */
}
