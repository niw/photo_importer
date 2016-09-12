//
//  PhotoFileAssetCell.swift
//  PhotoImporter
//
//  Created by Yoshimasa Niwa on 9/11/16.
//  Copyright © 2016 Yoshimasa Niwa. All rights reserved.
//

import UIKit
import PhotosUI

class PhotoFileAssetCell: UICollectionViewCell {
    static let reuseIdentifier = "PhotoFileAssetCell"

    private var preview: UIImageView?
    private var livePhotoIcon: UIImageView?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder:) is not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let preview = UIImageView(frame: bounds)
        preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(preview)
        self.preview = preview

        let livePhotoIcon = UIImageView(image: PHLivePhotoView.livePhotoBadgeImage(options: .overContent))
        livePhotoIcon.frame = CGRect(x: 2.0, y: 2.0, width: 20.0, height: 20.0)
        livePhotoIcon.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        addSubview(livePhotoIcon)
        self.livePhotoIcon = livePhotoIcon
    }

    override func prepareForReuse() {
        photoFileAsset = nil
    }

    var photoFileAsset: PhotoFileAsset? {
        didSet {
            livePhotoIcon?.isHidden = !(photoFileAsset?.isLivePhoto ?? false)

            preview?.image = nil
            photoFileAsset?.resource.renderPreview { [weak self] (image) in
                self?.preview?.image = image
            }
        }
    }
}
