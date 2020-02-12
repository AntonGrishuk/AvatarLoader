//
//  ViewController.swift
//  AvatarLoader
//
//  Created by Anton Grishuk on 28.01.2020.
//  Copyright © 2020 Anton Grishuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let imageUrls: Set<String> = [
    "https://images.unsplash.com/photo-1562113127-e5bcec12486b?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=3034&q=80",
    "https://images.unsplash.com/photo-1524639203153-736267488b2d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2647&q=80",
    "https://freebigpictures.com/wp-content/uploads/2009/09/blow-ball-spring.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/Мона-Лиза.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/Рождение-Венеры.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/Сотворение-Адама.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/утро-в-сосновом-лесу.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/девочка-на-шаре.jpg",
    "https://www.annaorion.com.ua/wp-content/uploads/2016/05/звездная-ночь.jpg"]
    
    @IBOutlet var imageView: UIImageView!
    
    var avatarLoader: AvatarLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        let placeholder = UIImage(named: "placeholderAvatar.png")
        self.avatarLoader = AvatarLoader(imageView: self.imageView, placeholder: placeholder, cachedImegesLimit: 5, cacheSize: 10 * 1024 * 1024)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
    }
        
    @IBAction func onLoadNextAvatar(_ sender: Any) {
        guard let urlString = self.imageUrls.randomElement() else { return }
        self.avatarLoader?.download(urlString, completionHandler: { (result) in
            print(result)
               })
    }


}

