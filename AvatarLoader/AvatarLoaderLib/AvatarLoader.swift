//
//  AvatarLoader.swift
//  AvatarLoader
//
//  Created by Anton Grishuk on 28.01.2020.
//  Copyright © 2020 Anton Grishuk. All rights reserved.
//

import UIKit

enum AvatarLoaderError: Error {
    case badURL
    case badData
    case downloadError
}

class AvatarLoader: NSObject {
    private let urlSession: URLSession
    private let downloadHandler = DownloadProcessHandler()
    private let imageView: UIImageView
    private let placeholderImage: UIImage?
    private var cache: NSCache = NSCache<NSString, UIImage>()
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    private let circlePath = UIBezierPath()
    private var currentImageUrlNSString: NSString?
    private var currentTask: URLSessionDownloadTask?
 
    public var completionHandler: ((Result<UIImage, AvatarLoaderError>)->())?
    
    // MARK: - Initialization and deinitialization
    
    init(imageView: UIImageView,
         placeholder: UIImage?,
         cachedImegesLimit: Int,
         cacheSize: Int)
    {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        self.urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                     delegate: downloadHandler,
                                     delegateQueue: operationQueue)
        self.imageView = imageView
        self.placeholderImage = placeholder
        
        super.init()
        
        self.cache.countLimit = cachedImegesLimit
        self.cache.totalCostLimit = cacheSize
        
        self.configureImageView()
        self.configureGradientLayer()
        self.subscribeOnProgress()
        self.subscribeOnDownloadHandler()
    }
    
    deinit {
        self.urlSession.finishTasksAndInvalidate()
    }
    
     // MARK: - Public
    
    func download(_ imageUrlString: String, completionHandler: @escaping(Result<UIImage, AvatarLoaderError>)->()) {
        if self.currentTask?.state == .running {
             return
        }
        self.completionHandler = completionHandler
        guard let preparedString = imageUrlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let imageUrl = URL(string: preparedString) else
        {
            completionHandler(.failure(.badURL))
            return
        }
        
        let imageUrlNSString = preparedString as NSString
        if let image = self.cache.object(forKey: imageUrlNSString) {
            DispatchQueue.main.async {
                self.imageView.image = image
                completionHandler(.success(image))
            }
            
            return
        }
        
        self.currentImageUrlNSString = imageUrlNSString
        
        self.currentTask = self.urlSession.downloadTask(with: imageUrl)
        self.currentTask?.resume()
    }
    
    // MARK: - Private
    
    private func image(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    private func configureImageView() {
        self.imageView.contentMode = .scaleAspectFill
        let imageViewShapeLayer = CAShapeLayer()
        let path = self.circlePath()
        imageViewShapeLayer.path = path
        imageViewShapeLayer.fillColor = UIColor.white.cgColor
        self.imageView.layer.mask = imageViewShapeLayer
        self.imageView.image = self.placeholderImage
    }
    
    private func configureGradientLayer() {
        self.gradientLayer.colors = [UIColor.green.cgColor, UIColor.red.cgColor]
        self.gradientLayer.locations = [0.0, 1.0]
                
        self.gradientLayer.frame = self.imageView.bounds
        
        self.shapeLayer.path = self.circlePath(angle: 0)
        self.gradientLayer.mask = self.shapeLayer
        self.shapeLayer.lineWidth = 10
        self.shapeLayer.strokeColor = UIColor.red.cgColor
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        
        self.imageView.layer.addSublayer(self.gradientLayer)
    }
    
    private func circlePath(angle: CGFloat = CGFloat.pi * 2) -> CGPath {
        let imageViewFrame = self.imageView.frame
        let imageViewMinSide = min(imageViewFrame.size.width, imageViewFrame.size.height)
        let path = UIBezierPath()
        
        path.addArc(withCenter: CGPoint(x: self.imageView.bounds.midX, y: self.imageView.bounds.midY), radius: imageViewMinSide / 2, startAngle: 0, endAngle: angle, clockwise: true)
        
        return path.cgPath
    }
    
    private func subscribeOnProgress() {
        self.downloadHandler.progressCompletionHandler = { [weak self] (progress: Float) in
            self?.shapeLayer.path = self?.circlePath(angle: CGFloat(progress) * CGFloat.pi * 2)
        }
    }
    
    private func subscribeOnDownloadHandler() {
        
        self.downloadHandler.completionHandler = { [weak self] result in
            DispatchQueue.main.async {
                
                self?.shapeLayer.path = self?.circlePath(angle: 0)
                
                switch result {
                case .success(let image):
                    self?.imageView.image = image
                    (self?.currentImageUrlNSString).map {
                        self?.cache.setObject(image, forKey: $0)
                    }
                    
                    self?.completionHandler?(.success(image))
                    
                    
                case .failure(_):
                    self?.completionHandler?(.failure(.downloadError))
                }
            }
        }
    }
    
}

fileprivate class DownloadProcessHandler: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    
    var progressCompletionHandler: ((Float)->())?
    var completionHandler: ((Result<UIImage, AvatarLoaderError>) -> ())?
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let data = try? Data.init(contentsOf: location), let image = UIImage(data: data) else
        {
            self.completionHandler?(.failure(.badData))
            return
        }
        
        self.completionHandler?(.success(image))
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let _ = error {
                self.completionHandler?(.failure(AvatarLoaderError.downloadError))
            }
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                
            DispatchQueue.main.async {
                self.progressCompletionHandler?(progress)
            }
        }
    }
    
}
