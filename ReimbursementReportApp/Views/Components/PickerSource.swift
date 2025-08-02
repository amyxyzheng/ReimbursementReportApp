//
//  PickerSource.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import SwiftUI

enum PickerSource: Identifiable {
    case camera, photoLibrary, documentPicker

    var id: Int { hashValue }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        case .documentPicker: return .photoLibrary // This won't be used for document picker
        }
    }
} 

