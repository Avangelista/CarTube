//
//  String.swift
//  Evyrest
//
//  Created by exerhythm on 14.12.2022.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
