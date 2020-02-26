//
//  GradeFetcher.swift
//  hipleech
//
//  Created by Thomas Mellenthin (Privat) on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum GradeFetcherError: Error, CustomStringConvertible {
    case httpError(Error)
    case response(String)
    case urlError(String)
    case invalidCredentials(String)
    case decoding

    public var description: String {
        switch self {
        case .httpError(let error): return "HTTP error: \(error.localizedDescription)"
        case .urlError(let url): return "Invalid URL: \(url)"
        case .response(let resp): return "Got unexpected response: \(resp)"
        case .invalidCredentials(let cred): return "Invalid credentials: \(cred)"
        case .decoding: return "Could not decode http-response"
        }
    }
}

public class GradeFetcher {
    
    private let completion: (Result<String, Error>) -> ()
    let url: String
    let user: String
    let password: String
    var cookieTask: URLSessionDataTask!
    var gradesTask: URLSessionDataTask!

    
    public init?(user: String, password: String, url: String, completion: @escaping (Result<String, Error>) -> ()) {
        self.url = url
        self.user = user.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        self.password = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        self.completion = completion

        guard !self.user.isEmpty else {
            completion(.failure(GradeFetcherError.invalidCredentials(user)))
            return
        }
        guard !self.password.isEmpty else {
            completion(.failure(GradeFetcherError.invalidCredentials(password)))
            return
        }
        requestCookie { [weak self] in
            self?.loginRequest()
        }
    }
    
    private func requestCookie(continueBlock: @escaping () -> ()) {
        guard let requestURL = URL(string: "\(url)/default.php") else {
            completion(.failure(GradeFetcherError.urlError(url)))
            return
        }
        cookieTask = URLSession.shared.dataTask(with: URLRequest.init(url: requestURL)) { [weak self] (data, response, error) in
            if let err = error {
                self?.completion(.failure(GradeFetcherError.httpError(err)))
                return
            }
            
            guard let resp = response, let httpResponse = (resp as? HTTPURLResponse), httpResponse.statusCode == 200 else {
                self?.completion(.failure(GradeFetcherError.response(response.debugDescription)))
                return
            }
            
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: httpResponse.allHeaderFields as! [String : String],
                                             for: resp.url!)
            HTTPCookieStorage.shared.setCookies(cookies, for: resp.url!, mainDocumentURL: nil)
            
             continueBlock()
        }
        cookieTask.resume()
    }
    
    private func loginRequest() {
        guard let requestURL = URL(string: "\(url)/login.php") else {
            completion(.failure(GradeFetcherError.urlError(url)))
            return
        }
        var request = URLRequest.init(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = "username=\(user)&password=\(password)&login=Anmelden".data(using: .utf8)!

        gradesTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let err = error {
                self?.completion(.failure(err))
                return
            }
            guard let htmlData = data, let html = String(data: htmlData, encoding: .utf8) else {
                self?.completion(.failure(GradeFetcherError.decoding))
                return
            }
            self?.completion(.success(html))
        }
        gradesTask.resume()
    }
}
