//
//  FilesTableViewController.swift
//  LiveVideoSplitter2
//
//  Created by rahulg on 06/05/18.
//  Copyright © 2018 rahulg. All rights reserved.
//

import UIKit

class FilesTableViewController: UITableViewController {
    var folderName = ""
    var fileArray = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        fileArray = getAllFiles(folder: folderName).sorted{ $0 > $1}
        
        tableView.reloadData()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fileArray.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileTableViewCell", for: indexPath)
        cell.textLabel?.text = fileArray[indexPath.row]
        return cell
    }
    
    func getAllFiles(folder: String) -> [String] {
        var dirs = [String]()
        do {
            dirs = try FileManager.default.contentsOfDirectory(atPath: FileManager.documentsDir() + "/\(folder)")
        } catch {
            print(error)
        }
        return dirs
    }


}
