//
//  EmailThreadRequest.swift
//  Charter
//
//  Created by Matthew Palmer on 20/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import Foundation
import RealmSwift

class EmailThreadNetworkDataSourceImpl: EmailThreadNetworkDataSource {
    fileprivate let session: URLSession
    fileprivate let username: String
    fileprivate let password: String
    
    required init(username: String? = nil, password: String? = nil, session: URLSession = URLSession.shared) {
        self.session = session
        
        if let username = username, let password = password {
            self.username = username
            self.password = password
        } else if username == nil || password == nil {
            let dictionary = NSDictionary(contentsOf: Bundle.main.url(forResource: "Credentials", withExtension: "plist")!)
            self.username = dictionary!["username"] as! String
            self.password = dictionary!["password"] as! String
        } else {
            fatalError("\(#file): Username and password must be provided to a request. Ensure that a Credentials.plist file exists with `username` and `password` set.")
        }
    }
    
    func getThreads(_ request: UncachedThreadRequest, completion: @escaping ([NetworkEmail]) -> Void) {
        let parameters = request.URLRequestQueryParameters
    
        var URLComponents = Foundation.URLComponents(string: "http://charter.ws:8080/charter/emails")!
        URLComponents.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        
        // We need to avoid double percent encoding the % sign.
        guard let fixedString = URLComponents.url?.absoluteString.replacingOccurrences(of: "%25", with: "%"), let fixedURL = URL(string: fixedString) else { return completion([]) }
        let URLRequest = NSMutableURLRequest(url: fixedURL)

        // TODO: Make HTTP basic auth reusable
        if let base64 = "\(username):\(password)"
            .data(using: String.Encoding.utf8)?
            .base64EncodedString(options: []) {
            URLRequest.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: URLRequest as URLRequest) { (data, response, error) -> Void in
            guard let data = data else { return completion([]) }
            do {
                guard let emails: [NetworkEmail] = try NetworkEmail.listFromJSONData(data) else { return completion([]) }
                completion(emails)
            } catch let e {
                print(e)
                completion([])
            }
        }
        
        task.resume()
    }
}
