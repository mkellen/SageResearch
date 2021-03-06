//
//  RSDTaskObject.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/// `RSDTaskObject` is the interface for running a task. It includes information about how to calculate progress,
/// validation, and the order of display for the steps.
public class RSDTaskObject : RSDUIActionHandlerObject, RSDTask, Decodable {

    /// A short string that uniquely identifies the task.
    public let identifier: String
    
    /// Information about the task.
    public var taskInfo: RSDTaskInfoStep?
    
    /// Information about the result schema.
    public var schemaInfo: RSDSchemaInfo?
    
    /// The step navigator for this task.
    public let stepNavigator: RSDStepNavigator
    
    /// A list of asynchronous actions to run on the task.
    public let asyncActions: [RSDAsyncActionConfiguration]?
    
    /// Default initializer.
    /// - parameters:
    ///     - taskInfo: Additional information about the task.
    ///     - stepNavigator: The step navigator for this task.
    ///     - schemaInfo: Information about the result schema.
    ///     - asyncActions: A list of asynchronous actions to run on the task.
    public init(taskInfo: RSDTaskInfoStep, stepNavigator: RSDStepNavigator, schemaInfo: RSDSchemaInfo? = nil, asyncActions: [RSDAsyncActionConfiguration]? = nil) {
        self.identifier = taskInfo.identifier
        self.taskInfo = taskInfo
        self.schemaInfo = schemaInfo
        self.stepNavigator = stepNavigator
        self.asyncActions = asyncActions
        super.init()
    }
    
    private enum CodingKeys : String, CodingKey {
        case identifier, taskInfo, schemaInfo, asyncActions
    }
    
    /// Initialize from a `Decoder`.
    ///
    /// - example:
    ///     ```
    ///        let json = """
    ///            {
    ///            "identifier" : "foo",
    ///            "schemaInfo" : {
    ///                            "identifier" : "foo.1.2",
    ///                            "revision" : 3 },
    ///                "steps": [
    ///                    {
    ///                        "identifier": "step1",
    ///                        "type": "instruction",
    ///                        "title": "Step 1"
    ///                    },
    ///                    {
    ///                        "identifier": "step2",
    ///                        "type": "instruction",
    ///                        "title": "Step 2"
    ///                    },
    ///                ]
    ///                "asyncActions" : [
    ///                     { "identifier" : "location", "type" : "location" }
    ///                ]
    ///            }
    ///        """.data(using: .utf8)! // our data in native (JSON) format
    ///     ```
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError` if there is a decoding error.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Set the identifier and
        let taskInfo: RSDTaskInfoStep?
        let identifier: String
        if let info = try container.decodeIfPresent(RSDTaskInfoStepObject.self, forKey: .taskInfo) {
            taskInfo = info
            identifier = info.identifier
        }
        else {
            if let info = decoder.taskInfo {
                taskInfo = info
                identifier = info.identifier
            }
            else {
                identifier = try container.decode(String.self, forKey: .identifier)
                taskInfo = decoder.taskDataSource?.taskInfo(with: identifier)
            }
        }
        
        self.taskInfo = taskInfo
        self.identifier = identifier
        
        // Look for a schema info
        self.schemaInfo = try container.decodeIfPresent(RSDSchemaInfoObject.self, forKey: .schemaInfo) ?? decoder.schemaInfo ?? decoder.taskDataSource?.schemaInfo(with: identifier)
        
        // Get the step navigator
        let factory = decoder.factory
        self.stepNavigator = try factory.decodeStepNavigator(from: decoder)
        
        // Decode the async actions
        if container.contains(.asyncActions) {
            var nestedContainer: UnkeyedDecodingContainer = try container.nestedUnkeyedContainer(forKey: .asyncActions)
            var decodedActions : [RSDAsyncActionConfiguration] = []
            while !nestedContainer.isAtEnd {
                let actionDecoder = try nestedContainer.superDecoder()
                if let action = try factory.decodeAsyncActionConfiguration(from: actionDecoder) {
                    decodedActions.append(action)
                }
            }
            self.asyncActions = decodedActions
        } else {
            self.asyncActions = nil
        }
        
        try super.init(from: decoder)
    }
    
    
    // MARK: RSDTask methods
    
    /// Instantiate a task result that is appropriate for this task.
    ///
    /// - returns: A task result for this task.
    public func instantiateTaskResult() -> RSDTaskResult {
        return RSDTaskResultObject(identifier: self.identifier, schemaInfo: self.schemaInfo)
    }
    
    /// Validate the task to check for any model configuration that should throw an error.
    /// - throws: An error appropriate to the failed validation.
    public func validate() throws {
        // Check if the step navigator implements step validation
        if let stepValidator = stepNavigator as? RSDStepValidator {
            try stepValidator.stepValidation()
        }
        
        // Check if the async action identifiers are unique
        if let actionIds = asyncActions?.map({ $0.identifier }) {
            let uniqueIds = Set(actionIds)
            if actionIds.count != uniqueIds.count {
                throw RSDValidationError.notUniqueIdentifiers("Action identifiers: \(actionIds.joined(separator: ","))")
            }
            // Loop through the async actions and validate them
            for asyncAction in asyncActions! {
                try asyncAction.validate()
                if let startIdentifier = asyncAction.startStepIdentifier {
                    guard stepNavigator.step(with: startIdentifier) != nil else {
                        throw RSDValidationError.identifierNotFound(asyncAction, startIdentifier, "Start step \(startIdentifier) not found for Async Action \(asyncAction.identifier).")
                    }
                }
            }
        }
    }
    
    
    // Overrides must be defined in the base implementation
    
    override class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        let thisKeys: [CodingKey] = allCodingKeys()
        keys.append(contentsOf: thisKeys)
        return keys
    }
    
    private static func allCodingKeys() -> [CodingKeys] {
        let codingKeys: [CodingKeys] = [.identifier, .taskInfo, .schemaInfo, .asyncActions]
        return codingKeys
    }
    
    override class func validateAllKeysIncluded() -> Bool {
        guard super.validateAllKeysIncluded() else { return false }
        let keys: [CodingKeys] = allCodingKeys()
        for (idx, key) in keys.enumerated() {
            switch key {
            case .identifier:
                if idx != 0 { return false }
            case .taskInfo:
                if idx != 1 { return false }
            case .schemaInfo:
                if idx != 2 { return false }
            case .asyncActions:
                if idx != 3 { return false }
            }
        }
        return keys.count == 4
    }
    
    class func examples() -> [[String : RSDJSONValue]] {
        let json: [String : RSDJSONValue] = [
                "identifier": "foo",
                "schemaInfo": [ "identifier": "foo.1.2", "revision": 2 ],
                "steps": [
                    [
                        "identifier": "step1",
                        "type": "instruction",
                        "title": "Step 1"
                    ],
                    [
                        "identifier": "step2",
                        "type": "instruction",
                        "title": "Step 2"
                    ]
                ],
                "asyncActions" : [["identifier" : "location", "type" : "location" ]]
            ]
        return [json]
    }
}

extension RSDTaskObject : RSDDocumentableDecodableObject {
}
