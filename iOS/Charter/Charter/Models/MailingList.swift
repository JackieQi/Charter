//
//  MailingListType.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 4/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol MailingListType {
    var identifier: String { get }
    var name: String { get }
}

struct _MailingList: MailingListType {
    let identifier: String
    let name: String
}

enum MailingList: RawRepresentable {
    typealias RawValue = MailingListType

    case swiftEvolution, swiftUsers, swiftDev, swiftBuildDev

    static var cases: [MailingList] = [.swiftEvolution, .swiftUsers, .swiftDev, .swiftBuildDev]

    init?(rawValue: MailingListType) {
        switch rawValue.identifier {
        case "swift-evolution":
            self = .swiftEvolution
        case "swift-users":
            self = .swiftUsers
        case "swift-dev":
            self = .swiftDev
        case "swift-build-dev":
            self = .swiftBuildDev
        default:
            return nil
        }
    }

    var rawValue: MailingListType {
        switch self {
        case .swiftEvolution:
            return _MailingList(identifier: "swift-evolution", name: Localizable.Strings.swiftEvolution)
        case .swiftUsers:
            return _MailingList(identifier: "swift-users", name: Localizable.Strings.swiftUsers)
        case .swiftDev:
            return _MailingList(identifier: "swift-dev", name: Localizable.Strings.swiftDev)
        case .swiftBuildDev:
            return _MailingList(identifier: "swift-build-dev", name: Localizable.Strings.swiftBuildDev)
        }
    }
}
