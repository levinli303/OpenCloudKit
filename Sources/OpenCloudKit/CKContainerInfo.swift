//
//  CKContainerInfo.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 25/07/2016.
//
//

import Foundation

struct CKContainerInfo {
    let environment: CKEnvironment

    let containerID: String

    init(containerID: String, environment: CKEnvironment) {
        self.containerID = containerID
        self.environment = environment
    }
}
