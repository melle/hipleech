//
//  File.swift
//  
//
//  Created by Thomas Mellenthin on 17.02.20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Commander
import libHipLeech

// MARK: - ⛑ Main logic

public class HipClient {
    
    let nickname: String
    let user: String
    let password: String
    let previousFile: String?
    let url: String
    let output: OutputFormat
    let scoreFormat: ScoreFormat
    let token: String?
    let chatID: String?
    
    var gradeFetcher: GradeFetcher!

    public init(nickname: String,
                user: String,
                password: String,
                previousFile: String? = nil,
                url: String,
                output: OutputFormat = .ascii,
                scoreFormat: ScoreFormat = .grades,
                telegram: String? = nil) {
        self.nickname = nickname
        self.user = user
        self.password = password
        self.previousFile = previousFile
        self.url = url
        self.output = output
        self.scoreFormat = scoreFormat
        
        if let parts = telegram?.components(separatedBy: "+"), parts.count == 2 {
             self.token = parts[0]
             self.chatID = parts[1]
        } else {
            self.token = nil
            self.chatID = nil
        }
    }
    
    public func run() {
        // Create a DispatchGroup
        let group = DispatchGroup()
        group.enter()
        
        guard let fetcher = GradeFetcher(user: self.user, password: self.password, url: self.url, completion: { [weak self] (result) in
            switch result {
            case .success(let html):
                
                let res = GradeParser.parse(html: html, scoreFormat: self?.scoreFormat ?? .grades)
                switch (res) {
                case .success(let tree):
                    self?.handleNewTree(tree, score: self?.scoreFormat ?? .grades)
                case .failure(let error ):
                    print(error.localizedDescription)
                }
                break
                
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
            group.leave()
        }) else {
            group.leave()
            return
        }
        self.gradeFetcher = fetcher
        group.wait()
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
    
    func handleNewTree(_ tree: HipTree, score: ScoreFormat) {
        guard let message = buildMessage(newTree: tree, previousTree: previousTree(), format: output, score: score, nickname: nickname) else {
            return
        }
        
        // save new tree
        do {
            try tree.asJSON.data(using: .utf8)?.write(to: previousFileURL())
        } catch {
            print(error.localizedDescription)
        }
        
        print(message)
        sendTelegram(message: message)
    }
    
    func buildMessage(newTree: HipTree, previousTree: HipTree, format: OutputFormat = .ascii, score: ScoreFormat, nickname: String) -> String? {
        
        let diff = HipTree.diff(oldTree: previousTree, newTree: newTree)
        guard diff.courses.count > 0 || diff.dah.count > 0 else { return nil }
        
        let averages: String = diff.courses.compactMap { (course: HipCourse) in
            if let course = newTree.course(named: course.name) {
                let avgString: String
                switch score {
                case .grades:
                    avgString = String(format: "%0.2f", course.currentAverage(as: score))
                case .points:
                    avgString = String(format: "%0.2f (%0.2f Punkte)", course.currentAverage(as: .grades), course.currentAverage(as: .points))
                }
                return "\(course.prettyName(format: .ascii)): \(avgString)"
            }
            return nil
        }.joined(separator: "\n")
        
        let currentAverage: String
        let totalAverage: String
        let totalPoints: String
        switch score {
        case .grades:
            currentAverage = String(format: "%0.2f", newTree.average(currentSemesterOnly: true, scoreFormat: .grades))
            totalAverage = String(format: "%0.2f", newTree.average(currentSemesterOnly: false, scoreFormat: .grades))
            totalPoints = ""
        case .points:
            currentAverage = String(
                format: "%0.2f (%0.2f Punkte)",
                newTree.average(currentSemesterOnly: true, scoreFormat: .grades),
                newTree.average(currentSemesterOnly: true, scoreFormat: .points)
            )
            totalAverage = String(
                format: "%0.2f (%0.2f Punkte)",
                newTree.average(currentSemesterOnly: false, scoreFormat: .grades),
                newTree.average(currentSemesterOnly: false, scoreFormat: .points)
            )
            totalPoints = "Gesamtpunktzahl: \(newTree.totalPoints)"
        }
        let bold = format == .markdown ? "*" : ""
        let result = """
                     🎓 \(bold)\(nickname)\(bold) 👨‍🏫

                     \(diff.prettyText(format: format, usePoints: scoreFormat == .points))
                     
                     \(bold)Notenschnitt\(bold)\(format == .ascii ? "\n------------------------" : "")
                     \(averages)
                     
                     Halbjahresschnitt: \(currentAverage)
                     Jahresschnitt: \(totalAverage)
                     \(totalPoints)
                     """
        return result
    }
    
    func sendTelegram(message: String) {
        guard let telegramToken = self.token, let telegramChatID = self.chatID else {
            return
        }
        
        let encodedMsg = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "<nil>"
        let parseMode = output == .markdown ? "&parse_mode=Markdown" : ""
        guard let url = URL(string: "https://api.telegram.org/bot\(telegramToken)/sendMessage?chat_id=\(telegramChatID)&text=\(encodedMsg)\(parseMode)") else {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error {
                print(error.localizedDescription)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }

}

// MARK: - 🎛 Command Line handling

// Commander does not print the usage if an argument is missing. We're partially duplicating the usage here:
let usage =
    """
    HipLeech - grade information from a given cevex Home.InfoPoint website. The output can be formatted as
    Ascii, JSON or Markdown. If a JSON-file with the previous grade information is provided, only the diff
    between the old and the current state is returned. By providing a Telegram API token and a chat ID,
    it is possible to send the grades to a Telegram bot.

    Usage:

        $ .build/x86_64-apple-macosx/debug/HipLeech <nickname> <username> <password> <url>

    Arguments:

        nickname - Used in the report only, helps to distuinguish multiple reports
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
    Option("input", default: "grades", flag: "i", description: "Input as grades or points"),
    Option("previousState", default: nil, flag: "p", description: "previous state file in json-format", validator: { (value) -> String? in return value }),
    Option("token", default: nil, flag: "t", description: "Telegram API token and chat ID, joined by a +, i.e. -t 123456781:DDEFHjcBgo-dkwpsJswEe+-6573342", validator: { (value) -> String? in return value }),
    Argument<String>("nickname", description: "Used in the report only, helps to distuinguish multiple reports"),
    Argument<String>("username", description: "Username (provided by the school)"),
    Argument<String>("password", description: "Password (provided by the school)"),
    Argument<String>("url", description: "Address of the Home.Infopoint installation, i.e. https://www.name-of-the-school.de/homeInfoPoint/")
) { output, input, previousState, telegram, nickname, username, password, url in
    let out: OutputFormat = output.map { (OutputFormat(rawValue: $0) ?? .ascii) } ?? .ascii
    let scoreFormat: ScoreFormat = ScoreFormat(rawValue: input) ?? .grades
    HipClient(nickname: nickname,
              user: username,
              password: password,
              previousFile: previousState,
              url: url,
              output: out,
              scoreFormat: scoreFormat,
              telegram: telegram).run()
   }.run()

