//
//  HomePageViewController.swift
//  FakeACGArt
//
//  Created by john on 15/12/2.
//  Copyright © 2015年 john. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage
import MWPhotoBrowser

private let cellIdentifier = "reuseIdentifier"

class HomePageViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        let itemWidth = (self.view.frame.size.width - 10 * 2 - 5 * 2) / 3 - 1
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 2)
        
        collectionView.registerNib(UINib(nibName: "ImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
        
        self.requestGlobalConfigData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestGlobalConfigData() {
        SVProgressHUD.show()
//        json_daily.php?device=iphone5&pro=yes&user=no&sexyfilter=yes&version=y.5.2
        var params: [String: AnyObject] = [:]
        params["device"] = "iphone5"
        params["pro"] = "yes"
        params["user"] = "yes"
        params["sexyfilter"] = "no"
        params["version"] = "y.5.2"
        ApiClient.request(.GET, "json_daily.php", parameters: params).responseJSON { (response) -> Void in
            SVProgressHUD.dismiss()
            if response.result.isFailure {
                return
            }
            if let retDic = response.result.value as? [String: AnyObject] {
                ResourceManager.UpdateResource(retDic)
            }
            self.collectionView.reloadData()
        }
    }

}

extension HomePageViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let data = ResourceManager.sharedResourceManager.GlobalConfig?["data"] as? [[String: AnyObject]] {
            if let imgs = data.first?["imgs"] as? [String] {
                return imgs.count
            }
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
        
        if let data = ResourceManager.sharedResourceManager.GlobalConfig?["data"] as? [[String: AnyObject]], let imgs = data.first?["imgs"] as? [String] {
            cell.image.sd_setImageWithURL(imageUrl(imgs[indexPath.item], size: .small)!, placeholderImage: UIImage(named: "img_bg"))
        } else {
            cell.image.image = UIImage(named: "img_bg")
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
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
extension HomePageViewController: MWPhotoBrowserDelegate {
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        guard let data = ResourceManager.sharedResourceManager.GlobalConfig?["data"] as? [[String: AnyObject]], let imgs = data.first?["imgs"] as? [String] else {
            return 0
        }
        return UInt(imgs.count)
    }
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        // 显示大图
        guard let data = ResourceManager.sharedResourceManager.GlobalConfig?["data"] as? [[String: AnyObject]], let imgs = data.first?["imgs"] as? [String] else {
            return nil
        }
        return MWPhoto(URL: imageUrl(imgs[Int(index)], size: .big)!)
    }
    
}
