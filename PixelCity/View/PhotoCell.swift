//
//  PhotoCell.swift
//  PixelCity
//
//  Created by Mahesh on 28/10/20.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    private var imgView : UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        imgView.contentMode = .scaleAspectFill
        self.addSubview(imgView)
        imgView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("Init coder has not been implemented")
    }
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(image : UIImage) {
        self.imgView.image = image
    }
}
