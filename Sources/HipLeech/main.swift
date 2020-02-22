//
//  File.swift
//  
//
//  Created by Thomas Mellenthin (Privat) on 17.02.20.
//

import Foundation
import Commander
import libHipLeech

// MARK: - ⛑ Main logic

public class HipClient {
    
    // FIXME: use Promises 🙄
    var areWeDoneYet = false

    let user: String
    let password: String
    let url: String
    let output: OutputFormat
    let token: String?
    let chatID: String?
    
    var gradeFetcher: GradeFetcher!

    public init(user: String,
                password: String,
                url: String,
                output: OutputFormat = .ascii,
                token: String? = nil,
                chatID: String? = nil) {
        self.user = user
        self.password = password
        self.url = url
        self.output = output
        self.token = token
        self.chatID = chatID
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
        return URL.init(fileURLWithPath: FileManager.default.currentDirectoryPath + "/hipleech-previous.json")
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
            if let avg = newTree.course(named: course.name)?.average {
                let avgString = String(format: "%0.1f", avg)
                return "Neuer Notenschnitt in \(course.prettyName): \(avgString)"
            }
            return nil
        }.joined(separator: "\n")
        
        let totalAverage = String(format: "%0.1f", newTree.totalAverage)
        
        let result = """
        \(diff.prettyText(format: format))
        
        Notenschnitt
        ------------------------
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
        print(url.absoluteURL)
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
        --token [default: ] - Telegram API token
        --chatID [default: ] - Telegram chat ID (i.e. "-6573342")
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
    Option("token", default: nil, flag: "t", description: "Telegram API token", validator: { (value) -> String? in return value }),
    Option("chatID", default: nil, flag: "c", description: "Telegram chat ID (i.e. \"-6573342\")", validator: { (value) -> String? in return value }),
    Argument<String>("username", description: "Username (provided by the school)"),
    Argument<String>("password", description: "Password (provided by the school)"),
    Argument<String>("url", description: "Address of the Home.Infopoint installation, i.e. https://www.name-of-the-school.de/homeInfoPoint/")
) { output, previousState, token, chatID, username, password, url in
    let out: OutputFormat = output.map { (OutputFormat(rawValue: $0) ?? .ascii) } ?? .ascii
    HipClient(user: username, password: password, url: url, output: out, token: token, chatID: chatID).run()
   }.run()

