//
//  SuggestCollectionViewController.swift
//  FakeACGArt
//
//  Created by john on 15/12/2.
//  Copyright © 2015年 john. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage
import MWPhotoBrowser

private let reuseIdentifier = "Cell"

class SuggestCollectionViewController: UICollectionViewController {
    
    var collectionDataHot: [String] = []
    
    var collectionDataTop: [String] = []
    
    var type: SuggestType = .hot

    override func viewDidLoad() {
        super.viewDidLoad()

        // 标题栏为分段控件
        let classTypeSegment = UISegmentedControl(items: ["今日热门", "TOP 400"])
        classTypeSegment.tintColor = UIColor.redColor()
        classTypeSegment.selectedSegmentIndex = 0
        classTypeSegment.addTarget(self, action: "switchSuggestType:", forControlEvents: .ValueChanged)
        self.navigationItem.titleView = classTypeSegment
        
        // 布局
        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        let itemWidth = (self.view.frame.size.width - 10 * 2 - 5 * 2) / 3 - 1
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 2)
        
        self.collectionView!.registerNib(UINib(nibName: "ImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        self.requestSuggestImageData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func switchSuggestType(sender: UISegmentedControl) {
        self.type = sender.selectedSegmentIndex == 0 ? .hot : .top
        if collectionDataTop.count == 0 {
            self.requestSuggestImageData()
        } else {
            self.collectionView!.reloadData()
        }
    }
    
    func requestSuggestImageData() {
        SVProgressHUD.show()
        var params: [String: AnyObject] = [:]
        params["device"] = "iphone5"
        params["pro"] = "yes"
        params["user"] = "no"
        params["sexyfilter"] = "no"
        params["version"] = "y.5.2"
        params["type"] = self.type.rawValue
        ApiClient.request(.GET, "json_list.php", parameters: params).responseJSON { (response) -> Void in
            SVProgressHUD.dismiss()
            if response.result.isFailure {
                return
            }
            if let data = response.result.value as? [String] {
                switch self.type {
                case .hot:
                    self.collectionDataHot = data
                case .top:
                    self.collectionDataTop = data
                }
            }
            self.collectionView!.reloadData()
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.type {
        case .hot:
            return self.collectionDataHot.count
        case .top:
            return self.collectionDataTop.count
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
    
        var imgStr: String
        switch self.type {
        case .hot:
            imgStr = self.collectionDataHot[indexPath.item]
        case .top:
            imgStr = self.collectionDataTop[indexPath.item]
        }
        cell.image.sd_setImageWithURL(imageUrl(imgStr, size: .small)!, placeholderImage: UIImage(named: "img_bg"))

        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let browser = MWPhotoBrowser(delegate: self)
        browser.displayActionButton = true; // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = false; // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = false; // Whether selection buttons are shown on each image (defaults to NO)
        browser.zoomPhotosToFill = true; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser.alwaysShowControls = false; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.startOnGrid = false; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        browser.autoPlayOnAppear = false; // Auto-play first video
        browser.setCurrentPhotoIndex(UInt(indexPath.item))
        
        self.navigationController?.pushViewController(browser, animated: true)
    }

}

// MARK: - 图片查看器代理
extension SuggestCollectionViewController: MWPhotoBrowserDelegate {
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        switch self.type {
        case .hot:
            return UInt(self.collectionDataHot.count)
        case .top:
            return UInt(self.collectionDataTop.count)
        }
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        var imgStr: String
        switch self.type {
        case .hot:
            imgStr = self.collectionDataHot[Int(index)]
        case .top:
            imgStr = self.collectionDataTop[Int(index)]
        }
        return MWPhoto(URL: imageUrl(imgStr, size: .big)!)
    }
    
}