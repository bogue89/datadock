//
//  ViewController.swift
//  DataDockDemo
//
//  Created by Jorge Benavides on 23/04/22.
//

import UIKit
import DataDock

class ViewController: UITableViewController {

    var dataDock = DataDock.default

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.backgroundColor = .clear
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        imageView.contentMode = .scaleAspectFill
        tableView.backgroundView = imageView

        let imageURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg")!
        dataDock.downloadTask(imageURL) { result in
            guard case let .success(data) = result else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "generic"
        return tableView.dequeueReusableCell(withIdentifier: id) ?? {
            let cell = UITableViewCell(style: .default, reuseIdentifier: id)
            cell.backgroundColor = .clear
            cell.imageView?.backgroundColor = .red
            cell.imageView?.frame.size = CGSize(width: 200, height: 200)
            return cell
        }()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let imageURL = URL(string: "https://picsum.photos/id/\(indexPath.item + 10)/200")!
        // only background configuration can continue after termination
        // but with the isDiscretionary setting on true, tasks will fail on auto-redirect
        dataDock.downloadTask(imageURL, completion: { result in
            guard case let .success(data) = result else { return }
            DispatchQueue.main.async {
                cell.imageView?.image = UIImage(data: data)
                cell.setNeedsLayout()
            }
        })
    }
}
