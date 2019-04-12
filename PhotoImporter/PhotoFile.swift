//
//  PhotoFile.swift
//  PhotoImporter
//
//  Created by Yoshimasa Niwa on 8/8/16.
//  Copyright © 2016 Yoshimasa Niwa. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

func DocumentDirectoryURL() -> URL? {
    return try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
}

struct PhotoFileResource {
    enum FileType {
        case JPG
        case PNG
        case GIF
        case HEIC
        case MOV
        case MP4

        init?(ofPathExcention pathExtension: String) {
            switch pathExtension.lowercased() {
            case "jpg", "jpeg":
                self = .JPG
            case "png":
                self = .PNG
            case "gif":
                self = .GIF
            case "heic":
                self = .HEIC
            case "mov":
                self = .MOV
            case "mp4":
                self = .MP4
            default:
                return nil
            }
        }
    }

    init?(atPath path: String) {
        guard let fileType = FileType(ofPathExcention: (path as NSString).pathExtension) else {
            return nil
        }
        self.fileType = fileType
        self.path = path
    }

    let fileType: FileType

    var isVideo: Bool {
        switch fileType {
        case .JPG, .PNG, .GIF, .HEIC:
            return false
        case .MOV, .MP4:
            return true
        }
    }

    let path: String

    var basename: String {
        return (path as NSString).lastPathComponent
    }

    func renderPreview(withCompletion completion: @escaping (UIImage?) -> Void) {
        switch fileType {
        case .JPG, .PNG, .GIF, .HEIC:
            completion(UIImage(contentsOfFile: path))
        case .MOV, .MP4:
            let asset = AVAsset(url: URL(fileURLWithPath: path))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTime.zero)]) { (requestedTime, image, actualTime, result, error) in
                DispatchQueue.main.async {
                    completion(image.map { (image) in UIImage(cgImage: image) })
                }
            }
        }
    }
}

struct PhotoFileAsset {
    let photoResource: PhotoFileResource?
    let videoResource: PhotoFileResource?

    var isLivePhoto: Bool {
        switch (photoResource, videoResource) {
        case (.some, .some):
            return true
        default:
            return false
        }
    }

    var resource: PhotoFileResource {
        return (photoResource ?? videoResource)!
    }

    init?(photoResource: PhotoFileResource?, videoResource: PhotoFileResource?) {
        switch (photoResource, videoResource) {
        case (nil, nil):
            return nil
        default:
            self.photoResource = photoResource
            self.videoResource = videoResource
        }
    }

    init(resource: PhotoFileResource) {
        switch resource.fileType {
        case .JPG, .PNG, .GIF, .HEIC:
            photoResource = resource
            videoResource = nil
        case .MOV, .MP4:
            photoResource = nil
            videoResource = resource
        }
    }

    func asset(withResource resource: PhotoFileResource) -> PhotoFileAsset? {
        switch (resource.fileType, photoResource, videoResource) {
        case (.JPG, nil, _):
            return PhotoFileAsset(photoResource: resource, videoResource: videoResource)
        case (.HEIC, nil, _):
            return PhotoFileAsset(photoResource: resource, videoResource: videoResource)
        case (.MOV, _, nil):
            return PhotoFileAsset(photoResource: photoResource, videoResource: resource)
        default:
            return nil
        }
    }

    static let enumeratorQueue = DispatchQueue(label: "PhotoFileAssetEnumeratorQueue")

    static func enumerateAssets(atPath path: String, withCompletion completion: @escaping ([PhotoFileAsset]?) -> Void) {
        enumeratorQueue.async {
            let result: [PhotoFileAsset]?

            if let files = FileManager.default.enumerator(atPath: path) {
                let assets = files.reduce([String : PhotoFileAsset]()) { (assets, file) in
                    var mutableAssets = assets
                    if let fileString = file as? String, let resource = PhotoFileResource(atPath: (path as NSString).appendingPathComponent(fileString)) {
                        let pathWithoutExtension = (resource.path as NSString).deletingPathExtension
                        if let asset = assets[pathWithoutExtension] {
                            if let newAsset = asset.asset(withResource: resource) {
                                mutableAssets[pathWithoutExtension] = newAsset
                            }
                        } else {
                            mutableAssets[pathWithoutExtension] = PhotoFileAsset(resource: resource)
                        }
                    }
                    return mutableAssets
                }
                result = assets.keys.sorted().map { (key) in assets[key]! }
            } else {
                result = nil
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
