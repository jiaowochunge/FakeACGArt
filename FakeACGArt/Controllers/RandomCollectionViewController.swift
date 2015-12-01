//
//  RandomCollectionViewController.swift
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

class RandomCollectionViewController: UICollectionViewController {
    
    var collectionData: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "随机"

        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        let itemWidth = (self.view.frame.size.width - 10 * 2 - 5 * 2) / 3 - 1
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 2)
        
        self.collectionView!.registerNib(UINib(nibName: "ImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        self.requestRandomImageData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestRandomImageData() {
        SVProgressHUD.show()
//        acg.sugling.in/json_list.php?device=iphone5&pro=yes&user=no&type=today_download&sexyfilter=yes&version=y.5.2
        var params: [String: AnyObject] = [:]
        params["device"] = "iphone5"
        params["pro"] = "yes"
        params["user"] = "no"
        params["sexyfilter"] = "no"
        params["version"] = "y.5.2"
        params["type"] = "today_download"
        ApiClient.request(.GET, "json_list.php", parameters: params).responseJSON { (response) -> Void in
            SVProgressHUD.dismiss()
            if response.result.isFailure {
                return
            }
            if let data = response.result.value as? [String] {
                self.collectionData = data
            }
            self.collectionView!.reloadData()
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
    
        cell.image.sd_setImageWithURL(imageUrl(collectionData[indexPath.item], size: .small)!, placeholderImage: UIImage(named: "img_bg"))
    
        return cell
    }

}
