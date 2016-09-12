//
//  ViewController.swift
//  PhotoImporter
//
//  Created by Yoshimasa Niwa on 8/6/16.
//  Copyright © 2016 Yoshimasa Niwa. All rights reserved.
//

import UIKit
import Photos

class Layout: UICollectionViewFlowLayout {
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        if let context = context as? UICollectionViewFlowLayoutInvalidationContext,
            self.collectionView?.bounds.size.width != newBounds.size.width {
            context.invalidateFlowLayoutDelegateMetrics = true
        }
        return context
    }
}

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView?
    private var progressView: UIProgressView?

    private var assets: [PhotoFileAsset]? {
        didSet {
            self.collectionView?.reloadData()
        }
    }

    private var cachedBoundsWidth: CGFloat?
    private var cachedItemSize: CGSize?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder:) is not implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Import", style: UIBarButtonItemStyle.done, target: self, action: #selector(ViewController.didTapDone(_:)))
    }

    override func loadView() {
        super.loadView()

        self.title = "Photos"

        if let view = self.view {
            view.backgroundColor = UIColor.white

            let layout = Layout()
            layout.minimumInteritemSpacing = 1.0
            layout.minimumLineSpacing = 1.0

            let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
            collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            collectionView.backgroundColor = UIColor.white
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(PhotoFileAssetCell.self, forCellWithReuseIdentifier: PhotoFileAssetCell.reuseIdentifier)
            view.addSubview(collectionView)
            self.collectionView = collectionView
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let documentDirectoryURL = DocumentDirectoryURL() {
            PhotoFileAsset.enumerateAssets(atPath: documentDirectoryURL.path) { [weak self] (photoFileAssets) in
                self?.assets = photoFileAssets
            }
        }
    }

    // MARK: - Actions

    func didTapDone(_ sender: Any) {
        let controller = UIAlertController(title: "Import photos", message: "Are you sure to import all these \(self.assets?.count ?? 0) photos?", preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Import", style: .destructive) { [weak self] (action) in
            self?.importPhotos()
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(controller, animated: true)
    }

    private func importPhotos() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            switch status {
            case .authorized:
                if let assets = self?.assets {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = false
                    PhotoImporter.import(fileAssets: assets, withProgressHandler: { [weak self] (progress) in
                        self?.navigationItem.prompt = "Importing... (\(Int(progress * 100)) %)"
                    }) { [weak self] (success, error) in
                        self?.navigationItem.prompt = nil
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                        let controller = UIAlertController(title: "Imported", message: error?.localizedDescription ?? "No errors", preferredStyle: .alert)
                        controller.addAction(UIAlertAction(title: "Done", style: .default))
                        self?.present(controller, animated: true)
                    }
                }
            default:
                return
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let boundsWidth = self.cachedBoundsWidth,
            boundsWidth == collectionView.bounds.size.width,
            let itemSize = self.cachedItemSize {
            return itemSize
        } else {
            let defaultItemSize = CGFloat(120.0)
            let spacing = (collectionViewLayout as! Layout).minimumInteritemSpacing

            let numberOfItemsInRow = round(collectionView.bounds.size.width / defaultItemSize)
            let width = (collectionView.bounds.size.width - (spacing * numberOfItemsInRow)) / numberOfItemsInRow
            let itemSize = CGSize(width: width, height: width)

            self.cachedBoundsWidth = collectionView.bounds.size.width
            self.cachedItemSize = itemSize

            return itemSize
        }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoFileAssetCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? PhotoFileAssetCell {
            cell.photoFileAsset = self.assets?[indexPath.item]
        }
        return cell
    }
}
