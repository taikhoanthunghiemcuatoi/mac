//
//  FlickrPhotosCollectionViewController.swift
//  CollectionViewDemo1
//
//  Created by MTV on 12/26/15.
//  Copyright (c) 2015 MTV. All rights reserved.
//

import UIKit

class FlickrPhotosCollectionViewController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    private let reuseIdentifier = "Cell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0);
    private var searches = [FlickrSearchResults]();
    private let flickr = Flickr();
    
    override func viewDidLoad() {
        print("calling viewDidLoad");
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        print("calling numberOfSectionsInCollectionView");
        return searches.count;
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        print("calling numberOfItemsInSection");
        return searches[section].searchResults.count;
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("calling cellForItemAtIndexPath");
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrPhotoViewCell
    
        // Configure the cell
        let flickrPhoto = photoForIndexPath(indexPath);
        cell.backgroundColor = UIColor.blackColor();
        cell.imageView.image = flickrPhoto.thumbnail;
        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if (sharing){
            let photo = photoForIndexPath(indexPath);
            selectedPhotos.append(photo);
            updateSharedPhotoCount();
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if (sharing){
            if let foundIndex = selectedPhotos.indexOf(photoForIndexPath(indexPath)){
                selectedPhotos.removeAtIndex(foundIndex);
                updateSharedPhotoCount();
            }
            
        }
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    private var selectedPhotos = [FlickrPhoto]();
    private let shareTextLabel = UILabel();
    
    func updateSharedPhotoCount(){
        shareTextLabel.text = "\(selectedPhotos.count) photos selected!";
        shareTextLabel.sizeToFit();
    }
    
    var sharing : Bool = false{
        didSet{
            collectionView?.allowsMultipleSelection = sharing;
            collectionView?.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None);
            selectedPhotos.removeAll(keepCapacity: false);
            if (sharing && largePhotoIndexPath != nil){
                largePhotoIndexPath = nil;
            }
            let shareButton = self.navigationItem.rightBarButtonItems![0] as UIBarButtonItem;
            if (sharing){
                let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel);
                navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true);
            }else{
                navigationItem.setRightBarButtonItems([shareButton], animated: true);
            }
        }
    }
    
    var largePhotoIndexPath : NSIndexPath?{
        didSet{
            var indexPaths = [NSIndexPath]();
            if (largePhotoIndexPath != nil){
                indexPaths.append(largePhotoIndexPath!);
            }
            collectionView?.performBatchUpdates({self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                return
                }){
                completed in
                if (self.largePhotoIndexPath != nil){
                    print("calling scrollToItemAtIndexPath");
                    self.collectionView?.scrollToItemAtIndexPath(self.largePhotoIndexPath!, atScrollPosition: .CenteredHorizontally, animated: true);
                }
            }
        }
    }
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        print("calling shouldSelectItemAtIndexPath");
        
        if (sharing){
            return true;
        }
        
        print("selected item at index path \(indexPath)");
        
        if (largePhotoIndexPath == indexPath){
            largePhotoIndexPath = nil;
        }else{
            largePhotoIndexPath = indexPath;
        }
        
        return false;
    }
    

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    func photoForIndexPath(indexPath : NSIndexPath) -> FlickrPhoto{
        return searches[indexPath.section].searchResults[indexPath.row];
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // 1
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        flickr.searchFlickrForTerm(textField.text!) {
            results, error in
            
            //2
            activityIndicator.removeFromSuperview()
            if error != nil {
                print("Error searching : \(error)")
            }
            
            if results != nil {
                //3
                print("Found \(results!.searchResults.count) matching \(results!.searchTerm)")
                self.searches.insert(results!, atIndex: 0)
                
                //4
                self.collectionView?.reloadData()
            }
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        print("calling sizeForItemAtIndexPath");
        let flickrPhoto =  photoForIndexPath(indexPath)
        
        // New code
        if indexPath == largePhotoIndexPath {
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
        
        // Previous code
        if var size = flickrPhoto.thumbnail?.size {
            size.width += 10
            size.height += 10
            return size
        }
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        print("calling viewForSupplementaryElementOfKind");
        //1
        switch kind {
            //2
        case UICollectionElementKindSectionHeader:
            //3
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind,withReuseIdentifier: "FlickrPhotoHeaderView",forIndexPath: indexPath) as! FlickrPhotoHeaderView
            headerView.label.text = searches[indexPath.section].searchTerm
            return headerView
        default:
            //4
            assert(false, "Unexpected element kind")
        }
    }
    
    
    @IBAction func share(sender: AnyObject) {
        if (searches.isEmpty){
            return;
        }
        
        if(!selectedPhotos.isEmpty){
            var imageArray = [UIImage]();
            for photo in selectedPhotos{
                imageArray.append(photo.thumbnail!);
            }
            
            let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil);
            let popover = UIPopoverController(contentViewController: shareScreen);
            popover.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItems![0], permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true);
        }
        
        sharing = !sharing;
        print("sharing: \(sharing)");
        
    }
}
