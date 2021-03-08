//
//  ImageCollectionViewController.swift
//  MyAlbum
//
//  Created by Jinyoung Kim on 2021/03/01.
//

import UIKit
import Photos

class ImageListViewController: UIViewController {
    
    enum ViewMode {
        case select, view
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var chooseModeButton: UIBarButtonItem!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var sortImageButton: UIBarButtonItem!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    var isImageNewestFirst: Bool!
    var fetchResult: PHFetchResult<PHAsset>!
    var titleTemp: String!
    let cellIdentifier: String = "imageCell"
    let imageManger: PHCachingImageManager = PHCachingImageManager()
    var viewMode: ViewMode = .view {
        didSet {
            switch viewMode {
            case .view:
                setButtonsViewMode(.view)
            case .select:
                setButtonsViewMode(.select)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        PHPhotoLibrary.shared().register(self)
        setFlowLayout()
        self.sortImageButton.title = "최신순"
        self.isImageNewestFirst = true
        self.titleTemp = self.title
        
        setButtonsViewMode(.view)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func setButtonsViewMode(_ viewMode: ViewMode) {
        switch viewMode {
        case .view:
            self.title = self.titleTemp
            self.chooseModeButton.title = "선택"
            self.actionButton.isEnabled = false
            self.sortImageButton.isEnabled = true
            self.trashButton.isEnabled = false
            
            guard let indexPaths = self.collectionView.indexPathsForSelectedItems else {
                return
            }
            
            for indexPath in indexPaths {
                self.collectionView.deselectItem(at: indexPath, animated: true)
                self.collectionView.cellForItem(at: indexPath)?.alpha = 1
            }
            
            self.collectionView.allowsMultipleSelection = false
        case .select:
            self.collectionView.allowsMultipleSelection = true
            
            self.title = "\(self.collectionView.indexPathsForSelectedItems?.count ?? 0)장 선택"
            self.chooseModeButton.title = "취소"
            self.actionButton.isEnabled = false
            self.sortImageButton.isEnabled = false
            self.trashButton.isEnabled = false
            
            
            guard let indexPaths = self.collectionView.indexPathsForSelectedItems else {
                return
            }

            if indexPaths.count > 0 {
                self.actionButton.isEnabled = true
                self.trashButton.isEnabled = true
            }
        }
    }
    
    func setFlowLayout() {
        let margin: CGFloat = 3
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = margin
        flowLayout.minimumLineSpacing = margin
        
        let width: CGFloat = (UIScreen.main.bounds.width - margin*2) / 3.0
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        self.collectionView.collectionViewLayout = flowLayout
    }
    
    func getIndex(indexPath: IndexPath) -> Int {
        if self.isImageNewestFirst {
            return indexPath.item
        } else {
            return self.fetchResult.count-indexPath.item-1
        }
    }
    
    @IBAction func sortImage(_ sender: Any) {
        if self.isImageNewestFirst {
            self.sortImageButton.title = "과거순"
        } else {
            self.sortImageButton.title = "최신순"
        }
        self.isImageNewestFirst = !self.isImageNewestFirst
        self.collectionView.reloadData()
    }
    
    @IBAction func chooseMode(_ sender: Any) {
        switch self.viewMode {
        case .view:
            self.viewMode = .select
        case .select:
            self.viewMode = .view
        }
    }
    
    @IBAction func trashSelectedImages(_ sender: Any) {
        guard let indexPaths = self.collectionView.indexPathsForSelectedItems else {
            return
        }
        var assetsToDelete: [PHAsset] = []
        for indexPath in indexPaths {
            let index = getIndex(indexPath: indexPath)
            assetsToDelete.append(self.fetchResult.object(at: index))
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        } completionHandler: { (_, _) in
            OperationQueue.main.addOperation {
                self.viewMode = .view
            }
        }
    }
    
    @IBAction func actionPopUp(_ sender: Any) {
        var imagesToShare: [UIImage] = []
        guard let indexPaths = self.collectionView.indexPathsForSelectedItems else {
            return
        }
        for indexPath in indexPaths {
            let index = getIndex(indexPath: indexPath)
            let asset = fetchResult.object(at: index)
            imageManger.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (image, _) in
                if let image = image {
                    imagesToShare.append(image)
                }
            }
        }
        let activityViewController = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension ImageListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: ImageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ImageCollectionViewCell else { fatalError("Unable to create collection view cell") }
        
        let index = getIndex(indexPath: indexPath)
        
        let asset: PHAsset = fetchResult.object(at: index)
        
        imageManger.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: nil) { (image, _) in
            cell.imageView.image = image
        }
        
        return cell
    }
}

extension ImageListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch self.viewMode {
        case .view:
            guard let nextViewController: ImageZoomViewController = self.storyboard?.instantiateViewController(identifier: "ImageZoomViewController") as? ImageZoomViewController else { fatalError("Unable to create Image Zoom View Controller") }
            
            let asset = self.fetchResult.object(at: indexPath.item)
            nextViewController.asset = asset
            
            let dateFormatter = DateFormatter()
            guard let date: Date = asset.creationDate else {
                return
            }

            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            dateFormatter.dateFormat = "YYYY-MM-dd"

            nextViewController.dateString = dateFormatter.string(from: date)

            dateFormatter.dateFormat = "a hh:mm:ss"

            nextViewController.timeString = dateFormatter.string(from: date)

            self.navigationController?.pushViewController(nextViewController, animated: true)
            
            self.collectionView.deselectItem(at: indexPath, animated: false)
        case .select:
            setButtonsViewMode(.select)
            self.collectionView.cellForItem(at: indexPath)?.alpha = 0.5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch self.viewMode {
        case .view:
            return
        case .select:
            setButtonsViewMode(.select)
            self.collectionView.cellForItem(at: indexPath)?.alpha = 1
        }
    }
}

extension ImageListViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        
        fetchResult = changes.fetchResultAfterChanges
        
        OperationQueue.main.addOperation {
            self.collectionView.reloadData()
        }
    }
}
