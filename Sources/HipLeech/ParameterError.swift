//
//  File.swift
//  
//
//  Created by Thomas Mellenthin on 20.02.20.
//

import Foundation

public enum ParameterError: Error, CustomStringConvertible {
    case output
    case fileNotFound(String)
    public var description: String {
        switch self {
        case .output: return "Output must be either ascii, json or markdown."
        case .fileNotFound(let file): return "Filenotfound \(file) !!!"
        }
    }
}
