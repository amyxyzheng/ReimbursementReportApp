#!/usr/bin/env swift

import Foundation
import AppKit

// iOS App Icon sizes
let iconSizes = [
    (1024, 1024), // App Store
    (180, 180),   // iPhone 6 Plus and later
    (167, 167),   // iPad Pro
    (152, 152),   // iPad, iPad mini
    (120, 120),   // iPhone 4 and later
    (87, 87),     // iPhone 6 Plus and later
    (80, 80),     // Spotlight
    (76, 76),     // iPad
    (60, 60),     // iPhone
    (40, 40)      // Spotlight
]

func generateAppIcons(from sourcePath: String, outputDirectory: String) {
    guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
        print("Error: Could not load source image from \(sourcePath)")
        return
    }
    
    // Create output directory if it doesn't exist
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: outputDirectory) {
        try? fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
    }
    
    for (width, height) in iconSizes {
        let size = NSSize(width: CGFloat(width), height: CGFloat(height))
        let resizedImage = NSImage(size: size)
        
        resizedImage.lockFocus()
        sourceImage.draw(in: NSRect(origin: .zero, size: size),
                        from: NSRect(origin: .zero, size: sourceImage.size),
                        operation: .copy,
                        fraction: 1.0)
        resizedImage.unlockFocus()
        
        if let tiffData = resizedImage.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            
            let filename = "\(width)x\(height).png"
            let outputPath = (outputDirectory as NSString).appendingPathComponent(filename)
            
            do {
                try pngData.write(to: URL(fileURLWithPath: outputPath))
                print("Generated: \(filename)")
            } catch {
                print("Error saving \(filename): \(error)")
            }
        }
    }
}

// Usage
if CommandLine.arguments.count < 3 {
    print("Usage: swift generate_app_icon.swift <source_image_path> <output_directory>")
    print("Example: swift generate_app_icon.swift icon.png ./AppIcons")
    exit(1)
}

let sourcePath = CommandLine.arguments[1]
let outputDirectory = CommandLine.arguments[2]

generateAppIcons(from: sourcePath, outputDirectory: outputDirectory)
print("App icon generation complete!") 