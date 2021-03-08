//
//  ImageZoomViewController.swift
//  MyAlbum
//
//  Created by Jinyoung Kim on 2021/03/01.
//

import UIKit
import Photos

class ImageZoomViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var heartButton: UIBarButtonItem!
    
    var asset: PHAsset?
    var dateString: String!
    var timeString: String!
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    lazy var titleStackView: UIStackView = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.text = self.dateString
        let subtitleLabel = UILabel()
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .gray
        subtitleLabel.font = subtitleLabel.font.withSize(13)
        subtitleLabel.text = self.timeString
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        PHPhotoLibrary.shared().register(self)
        changeHeartButton()
        navigationItem.titleView = titleStackView
        
        guard let asset = self.asset else {
            return
        }
        
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (image, _) in
            self.imageView.image = image
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
     
    func changeHeartButton() {
        guard let asset = self.asset else {
            return
        }
        if asset.isFavorite {
            self.heartButton.image = UIImage(systemName: "heart.fill")
        } else {
            self.heartButton.image = UIImage(systemName: "heart")
        }
    }
    
    @IBAction func trashImage(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([self.asset] as NSFastEnumeration)
        } completionHandler: { (success, error) in
            if success {
                OperationQueue.main.addOperation {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @IBAction func actionPopUp(_ sender: Any) {
        guard let asset = self.asset else {
            return
        }
        
        var imageToShare: UIImage?
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (image, _) in
            imageToShare = image
        }
        guard let image = imageToShare else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func selectHeartButton(_ sender: Any) {
        guard let asset = self.asset else {
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest(for: asset).isFavorite = !asset.isFavorite
        }, completionHandler: nil)
    }
}

extension ImageZoomViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}

extension ImageZoomViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let asset = self.asset else {
            return
        }
        
        guard let changes = changeInstance.changeDetails(for: asset) else {
            return
        }

        self.asset = changes.objectAfterChanges
        
        OperationQueue.main.addOperation {
            self.changeHeartButton()
        }
    }
}
