//
//  ServerFileTableViewswift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/17/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

class ServerFileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var lastModifiedLabel: UILabel!
    @IBOutlet weak var menuImageView: UIImageView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    public var serverFile: ServerFile? {
        didSet {
            guard let serverFile = serverFile else {
                return
            }
            
            fileNameLabel?.text = serverFile.name
            fileSizeLabel?.text = serverFile.getFileSize()
            lastModifiedLabel?.text = serverFile.getLastModifiedDate()
            
            setupArtWork()
        }
    }
    
    private func setupArtWork() {
        guard let serverFile = serverFile else {
            return
        }

        let type = Mimes.shared.match(serverFile.mime_type!)
        
        switch type {
            
        case MimeType.image:
            thumbnailImageView.sd_setImage(with: URL(string: ServerApi.shared!.getFileUri(serverFile).absoluteString), placeholderImage: UIImage(named: "image"), options: .refreshCached)
            break
            
        case MimeType.video:
            let url = URL(string: ServerApi.shared!.getFileUri(serverFile).absoluteString)!
            
            if let image = VideoThumbnailGenerator.imageFromMemory(for: url) {
                thumbnailImageView.image = image
            } else {
                let image = VideoThumbnailGenerator().getThumbnail(url)
                thumbnailImageView.image = image
            }
            break
            
        case MimeType.audio:
            let url = URL(string: ServerApi.shared!.getFileUri(serverFile).absoluteString)!
            
            if let image = AudioThumbnailGenerator.imageFromMemory(for: url) {
                thumbnailImageView.image = image
            } else {
                let image = AudioThumbnailGenerator().getThumbnail(url)
                thumbnailImageView.image = image
            }
            break
            
        case MimeType.presentation, MimeType.document, MimeType.spreadsheet:
            let url = URL(string: ServerApi.shared!.getFileUri(serverFile).absoluteString)!
            
            if let image = PDFThumbnailGenerator.imageFromMemory(for: url) {
                thumbnailImageView.image = image
            } else {
                let image = PDFThumbnailGenerator().getThumbnail(url)
                thumbnailImageView.image = image
            }
            
        default:
            thumbnailImageView.image = UIImage(named: "file")
            break
        }
    }
}
