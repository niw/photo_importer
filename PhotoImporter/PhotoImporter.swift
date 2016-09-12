//
//  PhotoImporter.swift
//  PhotoImporter
//
//  Created by Yoshimasa Niwa on 8/18/16.
//  Copyright © 2016 Yoshimasa Niwa. All rights reserved.
//

import Foundation
import Photos

extension PHAssetCreationRequest {
    func addResources(withFileAsset fileAsset: PhotoFileAsset) {
        let videoType: PHAssetResourceType
        if let resource = fileAsset.photoResource {
            addResource(with: .photo, fileURL: URL(fileURLWithPath: resource.path), options: nil)
            videoType = .pairedVideo
        } else {
            videoType = .video
        }
        if let resource = fileAsset.videoResource {
            addResource(with: videoType, fileURL: URL(fileURLWithPath: resource.path), options: nil)
        }
    }
}

struct PhotoImporter {
    static let importQueue = DispatchQueue(label: "PhotoImpoterImportQueue")

    static func `import`(fileAssets: [PhotoFileAsset], withProgressHandler progressHandler: @escaping (Double) -> Void, completion: @escaping (Bool, Error?) -> Void) {
        importQueue.sync {
            var count = 0
            for fileAsset in fileAssets {
                let semaphore = DispatchSemaphore(value: 0)
                var result: (Bool, Error?) = (false, nil)

                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResources(withFileAsset: fileAsset)
                }) { (success, error) in
                    result = (success, error)
                    semaphore.signal()
                }

                semaphore.wait()

                count += 1
                let progress = Double(count) / Double(fileAssets.count)
                DispatchQueue.main.async {
                    progressHandler(progress)
                }

                switch result {
                case (false, let error):
                    DispatchQueue.main.async {
                        completion(false, error)
                    }
                    return
                default:
                    break
                }
            }

            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
    }
}
