//
//  ViewController.swift
//  MyAlbum
//
//  Created by Jinyoung Kim on 2021/02/24.
//

import UIKit
import Photos

class AlbumListViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    var fetchResults: [PHFetchResult<PHAsset>] = []
    var assetCollections: [PHAssetCollection] = []
    let imageManger: PHCachingImageManager = PHCachingImageManager()
    let cellIdentifier: String = "albumCell"
    
    func requestCollections() {
        fetchResults.removeAll()
        assetCollections.removeAll()
        
        let fetchResult: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        fetchResult.enumerateObjects { (collection, count, stop) in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            self.fetchResults.append(fetchResult)
            self.assetCollections.append(collection)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "앨범"
        PHPhotoLibrary.shared().register(self)
        setFlowLayout()
        
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized:
            print("접근 허가됨")
            self.requestCollections()
        case .denied:
            print("접근 불허")
        case .notDetermined:
            print("아직 응답하지 않음")
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    print("사용자가 허용함")
                    self.requestCollections()
                case .denied:
                    print("사용자가 불허함")
                default:
                    break
                }
            }
        case .restricted:
            print("접근 제한")
        case .limited:
            print("일부 접근 제한")
        @unknown default:
            fatalError()
        }
        self.collectionView.reloadData()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nextViewController: ImageListViewController = segue.destination as? ImageListViewController else {
            return
        }
        guard let cell: AlbumCollectionViewCell = sender as? AlbumCollectionViewCell else {
            return
        }
        guard let indexPath = self.collectionView.indexPath(for: cell) else {
            return
        }
        
        nextViewController.fetchResult = self.fetchResults[indexPath.item]
        nextViewController.title = self.assetCollections[indexPath.item].localizedTitle
    }
    
    func setFlowLayout() {
        let itemsPerRow: CGFloat = 2
        let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        flowLayout.minimumInteritemSpacing = 10
//        flowLayout.minimumLineSpacing = 10
        let paddingSpace = flowLayout.sectionInset.left * (itemsPerRow + 1)
        let availableWidth = UIScreen.main.bounds.width - paddingSpace
        
        let width: CGFloat = availableWidth / itemsPerRow
//        let height: CGFloat = UIScreen.main.bounds.height / 4.0
        flowLayout.itemSize = CGSize(width: width, height: width * 1.3)
        
        self.collectionView.collectionViewLayout = flowLayout
    }
}

extension AlbumListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: AlbumCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? AlbumCollectionViewCell else { fatalError("Unable to create collection view cell") }
        let fetchResult: PHFetchResult<PHAsset> = self.fetchResults[indexPath.item]
        
        if fetchResult.count != 0 {
            let asset: PHAsset = fetchResult.firstObject!
            
            imageManger.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: nil) { (image, _) in
                cell.albumImageView.image = image
            }
        } else {
            cell.albumImageView.image = nil
        }
        cell.albumImageCount.text = String(fetchResult.count)
        cell.albumName.text = self.assetCollections[indexPath.item].localizedTitle
        
        return cell
    }
}

extension AlbumListViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        for i in 0..<self.fetchResults.count {
            if let changes = changeInstance.changeDetails(for: fetchResults[i]) {
                fetchResults[i] = changes.fetchResultAfterChanges
            }
        }
        
        OperationQueue.main.addOperation {
            self.collectionView.reloadData()
        }
    }
}

//extension AlbumListViewController: UICollectionViewDelegate {
//
//}
