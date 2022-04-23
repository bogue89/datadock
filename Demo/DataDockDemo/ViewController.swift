//
//  ViewController.swift
//  DataDockDemo
//
//  Created by Jorge Benavides on 23/04/22.
//

import UIKit
import DataDock

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.backgroundColor = .clear
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        tableView.backgroundView = imageView

        let imageURL = URL(string: "https://picsum.photos/id/666/200")!
        DataDock.shared.dataTask(imageURL) { data in
            guard let data = data else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1000
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "generic"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .default, reuseIdentifier: id)
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let imageURL = URL(string: "https://picsum.photos/id/\(indexPath.item)/200")!

        DataDock.shared.downloadTask(imageURL, completion: { data in
            guard let data = data else { return }
            DispatchQueue.main.async {
                cell.imageView?.image = UIImage(data: data)
            }
        })
    }
}

