//
//  File.swift
//  
//
//  Created by Thomas Mellenthin (Privat) on 17.02.20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Commander
import libHipLeech

// MARK: - ⛑ Main logic

public class HipClient {
    
    // FIXME: use Promises 🙄
    var areWeDoneYet = false

    let user: String
    let password: String
    let previousFile: String?
    let url: String
    let output: OutputFormat
    let token: String?
    let chatID: String?
    
    var gradeFetcher: GradeFetcher!

    public init(user: String,
                password: String,
                previousFile: String? = nil,
                url: String,
                output: OutputFormat = .ascii,
                telegram: String? = nil) {
        self.user = user
        self.password = password
        self.previousFile = previousFile
        self.url = url
        self.output = output
        
        if let parts = telegram?.components(separatedBy: "+"), parts.count == 2 {
             self.token = parts[0]
             self.chatID = parts[1]
        } else {
            self.token = nil
            self.chatID = nil
        }
    }
    
    public func run() {
        guard let fetcher = GradeFetcher(user: self.user, password: self.password, url: self.url, completion: { [weak self] (result) in
            switch result {
            case .success(let html):
                
                let res = GradeParser.parse(html: html)
                switch (res) {
                case .success(let tree):
                    self?.handleNewTree(tree)
                case .failure(let error ):
                    print(error.localizedDescription)
                    self?.areWeDoneYet = true
                }
                break
                
            case .failure(let error):
                print(error.localizedDescription)
                self?.areWeDoneYet = true
                break
            }
        }) else {
            return
        }
        self.gradeFetcher = fetcher
        
        while false == areWeDoneYet {
            RunLoop.main.run(until: Date.init(timeIntervalSinceNow: 0.01))
        }
    }

    fileprivate func previousFileURL() -> URL {
        let path: String
        if let file = previousFile {
            path = file
        } else {
            path = FileManager.default.currentDirectoryPath + "/hipleech-previous.json"
        }
        return URL.init(fileURLWithPath: path)
    }
    
    func previousTree() -> HipTree {
        
        let previousData: Data
        do {
            previousData = try Data(contentsOf: previousFileURL())
        } catch {
            // 404? could not read file? Return an empty tree
            return HipTree()
        }
        
        return HipTree.from(json: previousData)
    }
    
    func handleNewTree(_ tree: HipTree) {
        
        guard let message = buildMessage(newTree: tree, format: output) else {
            areWeDoneYet = true
            return
        }
        
        // save new tree
        do {
            print("writing to \(previousFileURL())")
            try tree.asJSON.data(using: .utf8)?.write(to: previousFileURL())
        } catch {
            print(error.localizedDescription)
        }
        
        print(message)
        sendTelegram(message: message)
        // areWeDoneYet = true
    }
    
    func buildMessage(newTree: HipTree, format: OutputFormat = .ascii) -> String? {
        
        let diff = HipTree.diff(oldTree: previousTree(), newTree: newTree)
        guard diff.courses.count > 0 else { return nil }
        
        let averages: String = diff.courses.compactMap { (course: HipCourse) in
            if let avg = newTree.course(named: course.name)?.currentAverage {
                let avgString = String(format: "%0.1f", avg)
                return "\(course.prettyName(format: .ascii)): \(avgString)"
            }
            return nil
        }.joined(separator: "\n")
        
        let totalAverage = String(format: "%0.1f", newTree.totalAverage)
        let bold = format == .markdown ? "*" : ""
        let result = """
                     \(diff.prettyText(format: format))
                     
                     \(bold)Notenschnitt\(bold)\(format == .ascii ? "\n------------------------" : "")
                     \(averages)
                     Gesamtschnitt: \(totalAverage)
                     """
        return result
    }
    
    func sendTelegram(message: String) {
        guard let telegramToken = self.token, let telegramChatID = self.chatID else {
            self.areWeDoneYet = true
            return
        }
        
        let encodedMsg = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "<nil>"
        let parseMode = output == .markdown ? "&parse_mode=Markdown" : ""
        guard let url = URL(string: "https://api.telegram.org/bot\(telegramToken)/sendMessage?chat_id=\(telegramChatID)&text=\(encodedMsg)\(parseMode)") else {
            self.areWeDoneYet = true
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            self?.areWeDoneYet = true
        }
        task.resume()
    }

}

// MARK: - 🎛 Command Line handling

// Commander does not prints the usage if an argument is missing. We're partially duplicating the usage here:
let usage =
    """
    HipLeech - grade information from a given cevex Home.InfoPoint website. The output can be formatted as
    Ascii, JSON or Markdown. If a JSON-file with the previous grade information is provided, only the diff
    between the old and the current state is returned. By providing a Telegram API token and a chat ID,
    it is possible to send the grades to a Telegram bot.

    Usage:

        $ .build/x86_64-apple-macosx/debug/HipLeech <username> <password> <url>

    Arguments:

        username - Username (provided by the school)
        password - Password (provided by the school)
        url - Address of the Home.Infopoint installation, i.e. https://www.name-of-the-school.de/homeInfoPoint/

    Options:
        --output [default: ascii] - Output format, either ascii, json or markdown
        --previousState [default: ] - previous state file in json-format
        --token [default: ] - Telegram API token and chat ID, joined by a +, i.e. -t 123456781:DDEFHjcBgo-dkwpsJswEe+-6573342
        --help - complete usage info
    """

if Swift.CommandLine.arguments.count == 1 {
    print(usage)
    exit(1)
}

command(
    Option("output", default: "ascii", flag: "o", description: "Output format, either ascii, json or markdown", validator: { (value) -> String? in
        guard OutputFormat.allCases.map({$0.rawValue}).contains(value) else { throw ParameterError.output }
        return value
    }),
    Option("previousState", default: nil, flag: "p", description: "previous state file in json-format", validator: { (value) -> String? in return value }),
    Option("token", default: nil, flag: "t", description: "Telegram API token and chat ID, joined by a +, i.e. -t 123456781:DDEFHjcBgo-dkwpsJswEe+-6573342", validator: { (value) -> String? in return value }),
    Argument<String>("username", description: "Username (provided by the school)"),
    Argument<String>("password", description: "Password (provided by the school)"),
    Argument<String>("url", description: "Address of the Home.Infopoint installation, i.e. https://www.name-of-the-school.de/homeInfoPoint/")
) { output, previousState, telegram, username, password, url in
    let out: OutputFormat = output.map { (OutputFormat(rawValue: $0) ?? .ascii) } ?? .ascii
    HipClient(user: username, password: password,  previousFile: previousState, url: url, output: out, telegram: telegram).run()
   }.run()

